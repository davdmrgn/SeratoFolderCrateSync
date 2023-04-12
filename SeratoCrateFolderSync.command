#!/usr/bin/env python3

import configparser
import os
import re
import struct
import time
from datetime import datetime
import logging
import shutil
import filecmp

### Paths + Config
#script_path = os.path.dirname(__file__)
script_path = os.path.dirname('.')
homedir = os.path.expanduser('~')
config = configparser.ConfigParser()
config.read(os.path.join(script_path, 'config.ini'))
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']
include_parent_crate = config['crates']['include_parent_crate']
updates = 0
test_mode = 'False'

### Logging
now = datetime.now()
logfile = '{}/Logs/SeratoCrateFolderSync-{}{}{}-{}{}.log'.format(library, str(now.year), '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute))
logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
logging.getLogger('').addHandler(console)
logging.debug('Session start')

def startApp():
  print()
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')
  print()
  if os.path.exists(library):
    logging.info('\tSerato Database:   ' + library)
  else:
    logging.error('\tSerato Database:   ' + ' - NOT FOUND')
  if os.path.exists(music):
    logging.info('\tMusic Library:   ' + music)
  else:
    logging.error('\tMusic Library:   ' + ' - NOT FOUND')
  if os.path.exists(os.path.join(script_path, 'config.ini')):
    logging.info('\tConfiguration File:   ' + os.path.join(script_path, 'config.ini'))
  else:
    logging.error('\tConfiguration File:   ' + ' - NOT FOUND')
  if os.path.exists(logfile):
    logging.info('\tLog File:   ' + logfile)
  else:
    logging.error('\tLog File:   ' + ' - NOT FOUND')
  print()
  logging.info('\tInclude parent folder as crate:   ' + include_parent_crate)
  print()
  file_count = []
  folder_count = []
  for root, dirs, files in os.walk(music):
    if include_parent_crate == 'True':
      folder_count.append(root)
    else:
      for dir in dirs:
        folder_count.append(dir)
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        file_count.append(file)
  print('Folders: {}\nFiles: {}'.format(len(folder_count), len(file_count)))
  mainmenu(folder_count, file_count)

def mainmenu(folder_count, file_count):
  print()
  print('L. Change _Serato_ database location')
  print('M. Change music location')
  print('P. Toggle include parent folder as crate setting')
  print()
  if library and music and len(folder_count) > 1 and len(file_count) > len(folder_count):
    print('S. Synchronize music folders to Serato crates')
    print('R. Rebuild music folders to Serato crates (delete exisitng)')
    print()
  if test_mode == 'True':
    print('T. Test Mode - Active: {}'.format(test_mode))
    print()
  print('Q. Quit')
  menu = str(input('\nSelect an option: ').lower())
  global rebuild
  if menu == 's':
    rebuild = 'False'
    sync_crates()
  elif menu == 'r':
    rebuild = 'True'
    sync_crates()
  elif menu == 'l':
    change_library_location(library)
  elif menu == 'm':
    pass
  elif menu == 'p':
    toggle_parent_folder_as_crate(include_parent_crate)
  elif menu == 't':
    toggle_test_mode()
  elif menu == 'q':
    quit()
  else:
    print('Invalid option')
    time.sleep(1)
    startApp()
  logging.debug('Session end')

def change_library_location(value):
  global library
  print('Current _Serato_ location:   ', value)
  print('New _Serato_ location: ')

def change_music_location(value):
  global music
  print('Current Music location:   ', value)
  print('New Music location: ')

def toggle_parent_folder_as_crate(value):
  global include_parent_crate
  if value == 'True':
    include_parent_crate = 'False'
  else:
    include_parent_crate = 'True'
  config.set('crates', 'include_parent_crate', include_parent_crate)
  with open('config.ini', 'w') as config_file:
    config.write(config_file)
  startApp()

def toggle_test_mode():
  global test_mode
  if test_mode == 'True':
    test_mode = 'False'
  else:
    test_mode = 'True'
  logging.info('Test mode: {}'.format(test_mode))
  time.sleep(1)
  startApp()

### Convert plain text list to binary crate file
def encode(data):
  result = b''
  i = 0
  for line in data:
    try:
      key = line[0].encode('utf-8')
      if isinstance(line[1], list):
        sub_list = line[1][0]
        sub_key = sub_list[0].encode('utf-8')
        sub_value = sub_list[1].encode('utf-16-be')
        sub_length = struct.pack('>I', len(sub_value))
        value = (sub_key + sub_length + sub_value)
      else:
        value = line[1].encode('utf-16-be')
      length = struct.pack('>I', len(value))
      result += (key + length + value)
      i += 1
    except:
      logging.error('ENCODE ERROR: i: {}, key: {}, length: {}, value: {}'.format(i, key, length, value))
      break
  return(result)

### Convert crate file data into lines of key, value - for future use
def decode(data):
  result = []
  i = 0
  while i < len(data):
    try:
      key = data[i:i+4].decode('utf-8')
      length = struct.unpack('>I', data[i+4:i+8])[0]
      binary = data[i+8:i+8 + length]
      if re.match('osrt|ovct|otrk', key):
        value = decode(binary)
        result.append((key, value))
      elif re.match('brev', key):
        if binary == b'\x00':
          value = ''
        else:
          value = decode(binary)
        result.append((key, value))
      else:
        value = binary.decode('utf-16-be')
        result.append((key, value))
      i += 8 + length
    except:
      logging.error('DECODE ERROR: i: {}, key: {}, length: {}, binary: {}, value: {}'.format(i, key, length, binary, value))
      break
  return(result)

### Copy library to temp folder
def temp_library():
  try:
    tempdir = os.path.join(library + 'Temp')
    logging.debug('Create temporary library at {}'.format(tempdir))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*')
    if os.path.exists(tempdir):
      logging.warning('Removing existing temporary library at {}'.format(tempdir))
      shutil.rmtree(tempdir)
    shutil.copytree(library, tempdir, ignore=copy_ignore)
    return(tempdir)
  except:
    logging.exception("An exception was thrown!")

### Scan music folders
def music_folder_scan():
  folder_crates = []
  for root, dirs, files in os.walk(music):
      if include_parent_crate == 'True':
        folder_crates.append(root)
      else:
        for dir in dirs:
          folder_crates.append(os.path.join(root, dir))
      folder_crates.sort()
  return(folder_crates)

### Check for existing crate, add if needed
def crate_check(temp_library, music_folders):
  for music_folder in music_folders:
    if include_parent_crate == 'True':
      crate_name = music_folder.replace(music, os.path.basename(music)).replace('/', '%%') + '.crate'
    else:
      crate_name = music_folder.replace(music, '')[1:].replace('/', '%%') + '.crate'
    crate_path = os.path.join(temp_library, 'Subcrates', crate_name)
    if os.path.exists(crate_path):
      if rebuild == 'True':
        logging.info('Rebuilding crate: {}'.format(crate_path))
        os.remove(crate_path)
        build_crate(crate_path, music_folder)
      else:
        logging.debug('Crate exists: {}'.format(crate_path))
        existing_crate(crate_path, music_folder)
    else:
      logging.debug('Crate does not exist: {}'.format(crate_path))
      build_crate(crate_path, music_folder)

### Build a new crate from scratch
def build_crate(crate_path, music_folder):
  global updates
  crate_name = os.path.split(crate_path)[-1]
  logging.info('Building new crate file from {}\tcrate file: {}'.format(music_folder, crate_path))
  crate_data = b''
  crate_data += encode([('vrsn', '1.0/Serato ScratchLive Crate')])
  crate_data += encode([('osrt', [('tvcn', 'song'), ('brev', '')])])
  crate_data += encode([('ovct', [('tvcn', 'song'), ('tvcw', '0')]), ('ovct', [('tvcn', 'artist'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bpm'), ('tvcw', '0')]), ('ovct', [('tvcn', 'key'), ('tvcw', '0')]), ('ovct', [('tvcn', 'year'), ('tvcw', '0')]), ('ovct', [('tvcn', 'grouping'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bitrate'), ('tvcw', '0')]), ('ovct', [('tvcn', 'undef'), ('tvcw', '0')]), ('ovct', [('tvcn', 'added'), ('tvcw', '0')]), ('ovct', [('tvcn', 'composer'), ('tvcw', '0')]), ('ovct', [('tvcn', 'comment'), ('tvcw', '0')]), ('ovct', [('tvcn', 'location'), ('tvcw', '0')]), ('ovct', [('tvcn', 'filename'), ('tvcw', '0')]), ('ovct', [('tvcn', 'genre'), ('tvcw', '0')]), ('ovct', [('tvcn', 'album'), ('tvcw', '0')]), ('ovct', [('tvcn', 'label'), ('tvcw', '0')])])
  for file in sorted(os.listdir(music_folder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      file_path = os.path.join(music_folder[1:], file)
      logging.info('Adding {} to crate {}'.format(file_path, crate_name))
      crate_data += encode([('otrk', [('ptrk', file_path)])])
  if len(crate_data) > 525:
    with open(crate_path, 'w+b') as crate_file:
      crate_file.write(crate_data)
    updates += 1
  pass

### Update existing crate
def existing_crate(crate_path, music_folder):
  global updates
  crate_name = os.path.split(crate_path)[-1]
  logging.debug('Checking existing crate - source: {}\tcrate file: {}'.format(music_folder, crate_path))
  with open(crate_path, 'rb') as f:
    crate_data = f.read()
  for file in sorted(os.listdir(music_folder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      file_path = os.path.join(music_folder, file)[1:]
      file_binary = encode([('otrk', [('ptrk', file_path)])])
      if crate_data.find(file_binary) != -1:
        logging.debug('{} exists in crate {}'.format(file, crate_name))
      else:
        logging.info('Adding {} to crate {}'.format(file, crate_name))
        with open(crate_path, 'ab') as crate_file:
          crate_file.write(file_binary)
        updates += 1

### Backup existing library
def backup_library():
  try:
    now = datetime.now()
    backup_folder = library + 'Backups/' + '_Serato_{}{}{}-{}{}{}'.format(now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute), '{:02d}'.format(now.second))
    logging.info('{} updates. Backing up library at {} to {}'.format(updates, library, backup_folder))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*')
    shutil.copytree(library, backup_folder, ignore=copy_ignore)
  except:
    logging.exception('Error backing up database')

### Move temp library to Serato library location
def move_library(temp_library):
  try:
    logging.info('Moving temp library {} to {}'.format(temp_library, library))
    shutil.copytree(os.path.join(temp_library, 'Subcrates'), os.path.join(library, 'Subcrates'), dirs_exist_ok=True)
  except:
    logging.exception('Error moving database')

def sync_crates():
  try:
    global temp_library
    temp_library = temp_library()
    music_folders = music_folder_scan()
    crate_check(temp_library, music_folders)
    if updates > 0:
      if test_mode == 'False':
        backup_library()
        move_library(temp_library)
      else:
        logging.info("We're in test mode. Not backing up or applying {} changes.".format(updates))
    else:
      logging.info('No updates to library required')
    logging.debug('Removing temporary library at {}'.format(temp_library))
    shutil.rmtree(temp_library)
  except:
    logging.exception("An exception was thrown!")

startApp()
