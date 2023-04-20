#!/usr/bin/env python3

import configparser
import os
import re
import struct
import time
from datetime import datetime
import logging
import shutil
import psutil

def header():
  print()
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')
  print()

# Search disks for Serato databases
def SearchDatabase():
  header()
  print('Scanning for Serato database')
  partitions = psutil.disk_partitions()
  database_search = []
  for p in partitions:
    if not re.search('dontbrowse', p.opts):
      database_search.append(p.mountpoint)
  homedir = os.path.expanduser('~')
  music_path = os.path.join(homedir, 'Music')
  if os.path.exists(music_path):
    database_search.append(music_path)
  serato_databases = []
  for d in database_search:
    database_path = os.path.join(d, '_Serato_')
    if os.path.exists(database_path):
      serato_databases.append(database_path)
  if len(serato_databases) == 1:
    logging.info('Serato database found: {}'.format(serato_databases[0]))
    time.sleep(1.5)
    return(serato_databases[0])
  elif len(serato_databases) > 1:
    logging.info('{} Serato databases found'.format(len(serato_databases)))
    return(SelectDatabase(serato_databases))
    time.sleep(1.5)
  else:
    logging.error('Serato database not found')
    time.sleep(1.5)

# Select a database if more than one exists
def SelectDatabase(serato_databases):
  print()
  print('Select the database')
  print()
  for number, path in enumerate(serato_databases):
    print('  {}. {}'.format(number + 1, path))
  try:
    menu = int(input('\nSelect an option: '))
    if menu > 0 and menu <= len(serato_databases):  
      return(serato_databases[menu - 1])
  except:
    pass

def StartLogging():
  ### Logging
  now = datetime.now()
  global logfile
  logfile = '{}/Logs/SeratoCrateFolderSync-{}{}{}-{}{}.log'.format(database, str(now.year), '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute))
  logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger('').addHandler(console)
  logging.debug('Session start')

# Find music location from Serato database
def FindMusic():
  serato_database = os.path.join(database, 'database V2')
  if os.path.exists(serato_database):
    print('Reading Serato database for music file location(s)')
    with open(serato_database, 'rb') as db:
      db_binary = db.read()
    db = decode(db_binary)
    if re.match('/Volumes', serato_database):
      file_base = serato_database.split('_Serato_')[0]
    else:
      file_base = '/'
    files = []
    for line in db:
      if line[0] == 'otrk':
        try:
          #print('Adding: {}'.format(os.path.join(file_base, line[1][1][1])))
          files.append(os.path.join(file_base, line[1][1][1]))
        except:
          pass
    if len(files) > 1:
      music_paths = []
      music_paths.append(os.path.commonprefix(files))
      if len(music_paths) == 1:
        logging.info('Music location found: {}'.format(os.path.normpath(music_paths[0])))
        time.sleep(1.5)
        return(os.path.normpath(music_paths[0]))
      elif len(music_paths) > 1:
        logging.info('{} Music locations found'.format(len(music_paths)))
        return(SelectMusicPath(os.path.normpath(music_paths[0])))
        time.sleep(1.5)
      else:
        logging.error(' Music locations not found')
        time.sleep(1.5)

def SelectMusicPath(music_paths):
  print()
  print('Select music path')
  print()
  for number, path in enumerate(music_paths):
    print('  {}. {}'.format(number + 1, path))
  menu = int(input('\nSelect an option: '))
  if menu > 0 and menu <= len(music_paths):  
    return(music_paths[menu - 1])

def startApp():
  #header()
  print()
  if os.path.exists(database):
    logging.info('Serato database:  ' + database)
  else:
    logging.error('Serato database:  ' + 'NOT FOUND')
  if os.path.exists(music):
    logging.info('Music Library:  ' + music)
  else:
    logging.error('Music Library:  ' + 'NOT FOUND')
  if os.path.exists(config_location):
    logging.info('Configuration File:  ' + config_location)
  else:
    logging.error('Configuration File:  ' + 'NOT FOUND')
  if os.path.exists(logfile):
    logging.info('Log File:  ' + logfile)
  else:
    logging.error('Log File:  ' + 'NOT FOUND')
  print()
  logging.info('Include parent folder as crate:  ' + include_parent_crate)
  if test_mode == 'True':
    logging.info('Test Mode: ENABLED'.format(test_mode))
  print()
  file_count = []
  folder_count = []
  print('Loading files', end='\r')
  for root, dirs, files in os.walk(music):
    if include_parent_crate == 'True':
      folder_count.append(root)
    else:
      for dir in dirs:
        folder_count.append(dir)
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        file_count.append(file)
  logging.info('Folders: {}   '.format(len(folder_count)))
  logging.info('Files: {}'.format(len(file_count)))
  mainmenu(folder_count, file_count)

def mainmenu(folder_count, file_count):
  print()
  print('L. Change _Serato_ database location')
  print('M. Change music location')
  print('P. Toggle include parent folder as crate setting')
  print('T. Toggle TEST mode (run without making changes)')
  print()
  if database and music and len(folder_count) > 1 and len(file_count) > len(folder_count):
    print('S. Synchronize music folders to Serato crates')
    print('R. Rebuild subcrates from scratch')
    print()
  print('Q. Quit')
  menu = str(input('\nSelect an option: ').lower())
  global rebuild
  if menu == 's':
    rebuild = 'False'
    sync_crates()
    if test_mode == 'True':
      startApp()
  elif menu == 'r':
    rebuild = 'True'
    sync_crates()
    if test_mode == 'True':
      startApp()
  elif menu == 'l':
    change_database_location(database)
  elif menu == 'm':
    change_music_location(music)
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

def change_database_location(value):
  global database
  logging.info('Current _Serato_ location:   ', value)
  value = str(input('\nEnter new database location: '))
  if os.path.exists(value):
    database = value
    config.set('paths', 'database', database)
    with open(config_location, 'w') as config_file:
      config.write(config_file)
  elif os.path.exists(os.path.join(homedir, value)):
    database = os.path.join(homedir, value)
  elif value == '':
    logging.info('Setting database back to default')
    time.sleep(2)
    database = homedir + config['paths']['database']
  else:
    logging.error('New database path not found')
    time.sleep(2)
    change_database_location(database)
  startApp()

def change_music_location(value):
  global music
  logging.info('Current Music location:   ', value)
  value = str(input('\nEnter new music location: '))
  if os.path.exists(value):
    music = value
    config.set('paths', 'music', music)
    with open(config_location, 'w') as config_file:
      config.write(config_file)
  elif os.path.exists(os.path.join(homedir, value)):
    music = os.path.join(homedir, value)
  elif value == '':
    logging.info('Setting music back to default')
    time.sleep(2)
    music = homedir + config['paths']['music']
  else:
    logging.error('New music path not found')
    time.sleep(2)
    change_music_location(music)
  startApp()

def toggle_parent_folder_as_crate(value):
  global include_parent_crate
  if value == 'True':
    include_parent_crate = 'False'
  else:
    include_parent_crate = 'True'
  config.set('crates', 'include_parent_crate', include_parent_crate)
  with open(config_location, 'w') as config_file:
    config.write(config_file)
  startApp()

def toggle_test_mode():
  global test_mode
  if test_mode == 'True':
    test_mode = 'False'
    logging.info('Test Mode: DISABLED')
  else:
    test_mode = 'True'
    logging.info('Test Mode: ENABLED')
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
      #print('key is {}\tlength is {}\tbinary is {}'.format(key, length, binary))
      if length < 4:
        value = binary.decode('utf-8')
      else:
        if re.match('osrt|ovct|otrk', key):
          value = decode(binary)
        else:
          value = binary.decode('utf-16-be', errors='ignore')
      i += 8 + length
      result.append((key, value))
    except:
      logging.debug('DECODE ERROR: i: {}, key: {}, length: {}, binary: {}, value: {}'.format(i, key, length, binary, value))
      break
  return(result)

### Copy database to temp folder
def make_temp_database():
  try:
    tempdir = os.path.join(database + 'Temp')
    logging.debug('Create temporary database at {}'.format(tempdir))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*')
    if os.path.exists(tempdir):
      logging.warning('Removing existing temporary database at {}'.format(tempdir))
      shutil.rmtree(tempdir)
    shutil.copytree(database, tempdir, ignore=copy_ignore)
    return(tempdir)
  except:
    logging.exception('We ran into a problem at make_temp_database')

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
def crate_check(temp_database, music_folders):
  for music_folder in music_folders:
    if include_parent_crate == 'True':
      crate_name = music_folder.replace(music, os.path.basename(music)).replace('/', '%%') + '.crate'
    else:
      crate_name = music_folder.replace(music, '')[1:].replace('/', '%%') + '.crate'
    crate_path = os.path.join(temp_database, 'Subcrates', crate_name)
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
  logging.info('\nBuilding new crate file {} from path {}'.format(crate_path, music_folder))
  crate_data = b''
  crate_data += encode([('vrsn', '1.0/Serato ScratchLive Crate')])
  crate_data += encode([('osrt', [('tvcn', 'song'), ('brev', '')])])
  crate_data += encode([('ovct', [('tvcn', 'song'), ('tvcw', '0')]), ('ovct', [('tvcn', 'artist'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bpm'), ('tvcw', '0')]), ('ovct', [('tvcn', 'key'), ('tvcw', '0')]), ('ovct', [('tvcn', 'year'), ('tvcw', '0')]), ('ovct', [('tvcn', 'grouping'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bitrate'), ('tvcw', '0')]), ('ovct', [('tvcn', 'undef'), ('tvcw', '0')]), ('ovct', [('tvcn', 'added'), ('tvcw', '0')]), ('ovct', [('tvcn', 'composer'), ('tvcw', '0')]), ('ovct', [('tvcn', 'comment'), ('tvcw', '0')]), ('ovct', [('tvcn', 'location'), ('tvcw', '0')]), ('ovct', [('tvcn', 'filename'), ('tvcw', '0')]), ('ovct', [('tvcn', 'genre'), ('tvcw', '0')]), ('ovct', [('tvcn', 'album'), ('tvcw', '0')]), ('ovct', [('tvcn', 'label'), ('tvcw', '0')])])
  for file in sorted(os.listdir(music_folder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_folder):
        music_root = os.path.split(database)[0]
        file_path = os.path.join(music_folder.replace(music_root, '')[1:], file)
      else:
        file_path = os.path.join(music_folder[1:], file)
      logging.info('Adding {} to {}'.format(file_path, crate_name.replace('%%', u' \u2771 ')))
      crate_data += encode([('otrk', [('ptrk', file_path)])])
      updates += 1
  if len(crate_data) > 525:
    with open(crate_path, 'w+b') as crate_file:
      crate_file.write(crate_data)
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
        #logging.debug('{} exists in crate {}'.format(file, crate_name))
        pass
      else:
        logging.info('Adding {} to {}'.format(file, crate_name.replace('%%', u' \u2771 ')))
        with open(crate_path, 'ab') as crate_file:
          crate_file.write(file_binary)
        updates += 1

### Backup existing database
def backup_database():
  try:
    now = datetime.now()
    backup_folder = database + 'Backups/' + '_Serato_{}{}{}-{}{}{}'.format(now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute), '{:02d}'.format(now.second))
    logging.info('\n{} updates. Backing up database at {} to {}'.format(updates, database, backup_folder))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*')
    shutil.copytree(database, backup_folder, ignore=copy_ignore)
  except:
    logging.exception('Error backing up database')

### Move temp database to Serato database location
def move_database(temp_database):
  try:
    logging.info('Moving temp database {} to {}'.format(temp_database, database))
    shutil.copytree(os.path.join(temp_database, 'Subcrates'), os.path.join(database, 'Subcrates'), dirs_exist_ok=True)
  except:
    logging.exception('Error moving database')

def sync_crates():
  try:
    global updates
    updates = 0
    global temp_database
    temp_database = make_temp_database()
    music_folders = music_folder_scan()
    crate_check(temp_database, music_folders)
    if updates > 0:
      if test_mode == 'False':
        backup_database()
        move_database(temp_database)
      else:
        logging.info("\n{} updates. Test Mode ENABLED. Not backing up or applying changes.".format(updates))
    else:
      logging.info('\nNo updates to subcrates required')
    time.sleep(4)
    logging.debug('Removing temporary database at {}'.format(temp_database))
    shutil.rmtree(temp_database)
  except:
    logging.exception('We ran into a problem at sync_crates')

os.system('clear')
database = SearchDatabase()
if database:
  StartLogging()
  music = FindMusic()
  if music:
    ### Paths + Config
    script_path = os.path.dirname(__file__)
    homedir = os.path.expanduser('~')
    config = configparser.ConfigParser()
    config_location = os.path.join(database, 'Logs', 'SeratoCrateFolderSync.ini')
    if os.path.exists(config_location):
      config.read(config_location)
    else:
      include_parent_crate = 'True'
      test_mode = 'True'
      config.add_section('crates')
      config.add_section('paths')
      config.add_section('modes')
      config.set('crates', 'include_parent_crate', include_parent_crate)
      config.set('modes', 'test_mode', test_mode)
      with open(config_location, 'w') as config_file:
        config.write(config_file)
    include_parent_crate = config['crates']['include_parent_crate']
    test_mode = config['modes']['test_mode']

    startApp()
  else:
    logging.error('Music location not found')
else:
  print('Serato database not found')
