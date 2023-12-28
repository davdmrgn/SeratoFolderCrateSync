#!/usr/bin/env python3

import os
import logging
import time
from datetime import datetime
import struct
import re
import configparser

def main():
  print('\n')
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')

  database_location = FindDatabase()
  config_location = ConfigFile(database_location)
  config = configparser.ConfigParser()
  config.read(config_location)
  include_parent_crate = config['crates']['include_parent_crate']
  database_decoded = ReadDatabase(database_location)
  database_music = DatabaseMusic(database_location, database_decoded)
  music_folder = MusicFolder(database_music)
  ShowInfo(database_location, config_location, logfile, database_music)
  music_folder_objects = MusicFolderObjects(music_folder, config_location)

  print('\nA. Advanced Options')
  print('P. {} include parent folder as crate'.format('Disable' if include_parent_crate == 'True' else 'Enable'))
  if database_location and music_folder and len(music_folder_objects[1]) > 1 and len(music_folder_objects[0]) > len(music_folder_objects[1]):
    print('X. Rebuild subcrates from scratch')
    print()
    print('\033[1m' + 'S. Synchronize music folders to Serato crates' + '\033[0m')
    print()
  print('H. Help')
  print()
  print('Q. Quit')


def FindDatabase():
  homedir = os.path.expanduser('~')
  music_path = os.path.join(homedir, 'Music')
  volumes = os.listdir('/Volumes')
  database_search = []
  for volume in volumes:
    database_search.append(os.path.join('/Volumes', volume))
  if os.path.exists(music_path):
    database_search.append(music_path)
  serato_databases = []
  for database in database_search:
    database_path = os.path.join(database, '_Serato_')
    if os.path.exists(database_path):
      serato_databases.append(database_path)
  if len(serato_databases) == 1:
    return serato_databases[0]
  else:
    return SelectDatabase(serato_databases)

def SelectDatabase(serato_databases):
  if len(serato_databases) == 0:
    import tkinter
    from tkinter import filedialog
    root = tkinter.Tk()
    root.withdraw()
    print('Select a Serato database folder using the file chooser')
    time.sleep(3)
    return filedialog.askdirectory()
  else:
    print('{} Serato databases found\n'.format(len(serato_databases)))
    for number, path in enumerate(serato_databases):
      print(' {}. {}'.format(number + 1, path))
    print('\n {}. Select a new path'.format(len(serato_databases) + 1))
    while True:
      menu = input('\nSelect an option: ')
      try:
        if menu == '':
          menu = 0
        else:
          menu = int(menu)
      except ValueError:
        print('Invalid option')
        time.sleep(1)
      else:
        break
    if menu > 0 and menu <= len(serato_databases):
      return(serato_databases[menu - 1])

### Logging
def StartLogging(database_location):
  now = datetime.now()
  global logfile
  logfile = '{}/Logs/SeratoCrateFolderSync-{}{}{}.log'.format(database_location, str(now.year), '{:02d}'.format(now.month), '{:02d}'.format(now.day))
  logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger('').addHandler(console)
  logging.debug('Session start')

def ConfigFile(database_location):
  config = configparser.ConfigParser()
  config_location = os.path.join(database_location, 'Logs', 'SeratoCrateFolderSync.ini')
  if os.path.exists(config_location):
    config.read(config_location)
  else:
    include_parent_crate = 'True'
    config.add_section('crates')
    config.add_section('paths')
    config.set('crates', 'include_parent_crate', include_parent_crate)
    with open(config_location, 'w') as config_file:
      config.write(config_file)
  return config_location

def DecodeBinary(input):
  output = []
  i = 0
  l = 0
  while i < len(input):
    j = i + 4
    key_binary = input[i:j]
    key = key_binary.decode('utf-8')
    k = j + 4
    length_binary = input[j:k]
    length = struct.unpack('>I', length_binary)[0]
    value_binary = input[k:k + length]
    if key == 'otrk':
      value = DecodeBinary(value_binary)
      l = l + 1
      print('Decoding {}: {}'.format(l, value[1][1][:140]), end='\r')
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

def ReadDatabase(database_location):
  database_file = os.path.join(database_location, 'database V2')
  if os.path.exists(database_file):
    StartLogging(database_location)
    logging.info('\nReading Serato database: {}'.format(database_file))
    with open(database_file, 'rb') as db:
      database_binary = db.read()
    database_decoded = DecodeBinary(database_binary)
    return database_decoded
  else:
    print('\nSerato database not found!')

def DatabaseMusic(database_location, database_decoded):
  database_music = []
  database_music_missing = []
  logging.info('\n{}Extracting song file locations from database'.format('\033[1F\033[K'))
  if re.match('/Volumes', database_location):
    file_base = database_location.split('_Serato_')[0]
  else:
    file_base = '/'
  for line in database_decoded:
    if line[0] == 'otrk':
      file_path = os.path.join(file_base, line[1][1][1])
      if os.path.exists(file_path):
        print('Adding {}: {}'.format(len(database_music) + 1, file_path[:140]), end='\r')
        database_music.append(file_path)
      else:
        logging.warning('\n{}File in database does not exist! {}'.format('\033[1F\033[K', file_path))
        database_music.append(file_path)
        database_music_missing.append(file_path)
  database_music.sort()
  return database_music, database_music_missing

def MusicFolder(database_music):
  ### Get all folders from all files
  folder_names = []
  for file in database_music[0]:
    folder_names.append(os.path.dirname(file))

  ### Top level directories, by length
  top_folders = sorted(set(folder_names), key=len)[:10]

  ### Filter out directories with no subfolders
  folder_counts = {}
  for path in top_folders:
    for root, dirs, files in os.walk(path):
      if len(dirs) > 1:
        logging.debug('Found music directory {} with {} subdirectories'.format(root, len(dirs)))
        folder_counts.update({root: len(dirs)})

  ### Find directories with shortest length and sub directories
  intersected_dirs = set(top_folders).intersection(set(folder_counts))

  ### Compile a list of instersected directories and add counts
  found_folders = {}
  for folder_name in intersected_dirs:
    logging.debug('Intersected directory: {}'.format(folder_name))
    found_folders.update({folder_name: folder_counts[folder_name]})

  # Sort the counts
  found_folders = dict(sorted(found_folders.items(), key=lambda item: item[1], reverse=True))
  logging.debug('Found paths: {}'.format(found_folders))

  folder_check = []
  for found_folder in found_folders:
    folder_check.append(found_folder)

  if folder_check[0] == os.path.commonpath(folder_check):
    logging.debug('Music location found: {}'.format(folder_check[0]))
    return list(found_folders)[0]
  else:
    SelectMusicFolder(found_folders)

### Change music root to sync
def SelectMusicFolder(found_folders):
  logging.info('\nTop {} music locations shown (from Serato database)'.format(len(found_folders)))
  print('\nSelect music folder to sync as subcrates\n')
  for number, path in enumerate(found_folders):
    print(' {}. {}'.format(number + 1, path))
  print('\n {}. Select a new path'.format(len(found_folders) + 1))
  while True:
    menu = input('\nSelect an option: ')
    try:
      if menu == '':
        menu = 0
      else:
        menu = int(menu)
    except ValueError:
      logging.error('Invalid option')
      time.sleep(1)
    else:
      break
  if menu > 0 and menu <= len(found_folders):
    return(list(found_folders)[menu - 1])
  elif menu == len(found_folders) + 1:
    import tkinter
    from tkinter import filedialog
    root = tkinter.Tk()
    root.withdraw()
    logging.info('Select a folder to sync using the file chooser')
    time.sleep(3)
    return filedialog.askdirectory()

def ShowInfo(database_location, config_location, logfile, database_music):
  logging.info('\n{}\nSerato Database: {}'.format('\033[1F\033[K', database_location))
  logging.info('Configuration File: {}'.format(config_location))
  logging.info('Log File: {}'.format(logfile))
  config = configparser.ConfigParser()
  config.read(config_location)
  include_parent_crate = config['crates']['include_parent_crate']
  logging.info('\nDatabase Files: {}'.format(len(database_music[0])) if database_music[1] == 0 else 'Database Files: {} ({} Missing)'.format(len(database_music[0]), len(database_music[1])))
  logging.info('\nInclude Parent Folder as Crate:  {}'.format('YES' if include_parent_crate == 'True' else 'NO'))

def MusicFolderObjects(music_folder, config_location):
  logging.info('\nMusic Folder: {}'.format(music_folder))
  music_folder_files = []
  music_folder_folders = []
  config = configparser.ConfigParser()
  config.read(config_location)
  include_parent_crate = config['crates']['include_parent_crate']
  for root, dirs, files in os.walk(music_folder):
    if include_parent_crate == 'True':
      music_folder_folders.append(root)
    else:
      for dir in dirs:
        music_folder_folders.append(dir)
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        music_folder_files.append(file)
  logging.info('Music Folder Folders: {}   '.format(len(music_folder_folders)))
  logging.info('Music Folder Files: {}'.format(len(music_folder_files)))
  return music_folder_files, music_folder_folders

if __name__ == "__main__":
  if os.name == 'posix':
    main()
