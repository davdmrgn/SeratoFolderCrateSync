#!/usr/bin/env python3

import os
import logging
import time
from datetime import datetime
import struct
import re
import configparser
import sys
import shutil
import io

def Header():
  print()
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')
  print()

def Main():
  serato_folder = FindDatabase()
  backup_folder = os.path.join(serato_folder + 'Backups')
  log_location = StartLogging(serato_folder)
  config = ConfigFile(serato_folder)
  include_parent_crate = config['crates']['include_parent_crate']
  database_decoded = ReadDatabase(serato_folder)
  database_music = DatabaseMusic(serato_folder, database_decoded)
  music_folder = MusicFolder(database_music)
  ShowInfo(serato_folder, config, log_location, database_music)
  music_folder_objects = MusicFolderObjects(music_folder, config)
  while True:
    menu = ShowMenu(include_parent_crate, serato_folder, music_folder, music_folder_objects)
    if menu == 'a':
      menu = AdvancedMenu(backup_folder)
      if menu == 'b':
        BackupDatabase(serato_folder)
        Header()
        Main()
      elif menu == 'r':
        RestoreDatabase(backup_folder, serato_folder)
      elif menu == 'u':
        ReplacePath(serato_folder, database_decoded, database_music)
        Header()
        Main()
      elif menu == 'x':
        SyncCrates(serato_folder, music_folder, config, 'True')
    elif menu == 's':
      SyncCrates(serato_folder, music_folder, config, 'False')
    elif menu == 'p':
      ToggleParentFolderAsCrate(config, serato_folder)
    elif menu == 'h':
      Help()
      Header()
      Main()
    elif menu == 'q':
      logging.debug('Session end')
      sys.exit(0)
    else:
      logging.error('Invalid option')
      time.sleep(1)

def ShowMenu(include_parent_crate, serato_folder, music_folder, music_folder_objects):
  print()
  if serato_folder and music_folder and len(music_folder_objects[1]) > 1 and len(music_folder_objects[0]) > len(music_folder_objects[1]):
    print('\033[1mS. Synchronize music folders to Serato crates\033[0m\n')
  print('P. {} include parent folder as crate'.format('Disable' if include_parent_crate == 'True' else 'Enable'))
  print('A. Advanced Options')
  print('H. Help')
  print('\nQ. Quit')
  menu = str(input('\nSelect an option: ').lower())
  return menu

def AdvancedMenu(backup_folder):
  print('\nB. Backup Database')
  if os.path.exists(backup_folder):
    print('R. Restore database from backup')
  print('X. Rebuild subcrates from scratch')
  print('U. Update music folder path in database')
  menu = str(input('\nSelect an option: ').lower())
  return menu

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
    logging.info('Select a Serato database folder using the file chooser')
    time.sleep(3)
    return filedialog.askdirectory()
  else:
    logging.info('{} Serato databases found\n'.format(len(serato_databases)))
    for number, path in enumerate(serato_databases):
      logging.info(' {}. {}'.format(number + 1, path))
    logging.info('\n {}. Select a new path'.format(len(serato_databases) + 1))
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
    if menu > 0 and menu <= len(serato_databases):
      return(serato_databases[menu - 1])

### Logging
def StartLogging(serato_folder):
  now = datetime.now()
  log_location = '{}/Logs/SeratoCrateFolderSync-{}{}{}.log'.format(serato_folder, str(now.year), '{:02d}'.format(now.month), '{:02d}'.format(now.day))
  logging.basicConfig(filename=log_location, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger('').addHandler(console)
  logging.debug('Session start')
  return log_location

def ConfigFile(serato_folder):
  config = configparser.ConfigParser()
  config_location = os.path.join(serato_folder, 'Logs', 'SeratoCrateFolderSync.ini')
  if os.path.exists(config_location):
    config.read(config_location)
  else:
    config.add_section('crates')
    config.add_section('paths')
    include_parent_crate = 'True'
    config.set('crates', 'include_parent_crate', include_parent_crate)
    os.makedirs(os.path.dirname(config_location), exist_ok=True)
    with open(config_location, 'w') as config_file:
      config.write(config_file)
  return config

def ToggleParentFolderAsCrate(config, serato_folder):
  include_parent_crate = config['crates']['include_parent_crate']
  if include_parent_crate == 'True':
    include_parent_crate = 'False'
  else:
    include_parent_crate = 'True'
  config_location = os.path.join(serato_folder, 'Logs', 'SeratoCrateFolderSync.ini')
  config.set('crates', 'include_parent_crate', include_parent_crate)
  with open(config_location, 'w') as config_file:
    config.write(config_file)
  Main()

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
    if re.match('^o', key):
      value = DecodeBinary(value_binary)
      l = l + 1
      terminal_width = os.get_terminal_size().columns - 20
      if len(value) != 1:
        print('Decoding {}: {}'.format(l, value[1][1][:terminal_width]), end='\033[K\r')
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

def Encode(input):
  print()
  l = 0
  output = io.BytesIO()
  for line in input:
    key = line[0]
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
    elif re.match('^o', key):
      o_values = line[1]
      l = l + 1
      terminal_width = os.get_terminal_size().columns - 20
      if len(o_values) != 1:
        logging.info('{}Encoding {}: {}'.format('\033[1F\033[K', l, o_values[1][1][:terminal_width]))
      value_binary = b''
      for line in o_values:
        o_key = line[0]
        o_key_binary = o_key.encode('utf-8')
        o_value = line[1]
        if isinstance(o_value, bytes):
          o_value_binary = o_value
        else:
          o_value_binary = o_value.encode('utf-16-be')
        o_length_binary = struct.pack('>I', len(o_value_binary))
        value_binary += (o_key_binary + o_length_binary + o_value_binary)
    length_binary = struct.pack('>I', len(value_binary))
    output.write(key_binary + length_binary + value_binary)
  logging.info('{}Encoded {} objects{}'.format('\033[1F', l, '\033[K\n'))
  return output.getvalue()

def ReadDatabase(serato_folder):
  database_file = os.path.join(serato_folder, 'database V2')
  if os.path.exists(database_file):
    StartLogging(serato_folder)
    logging.info('Reading Serato database: {}'.format(database_file))
    with open(database_file, 'rb') as db:
      database_binary = db.read()
    database_decoded = DecodeBinary(database_binary)
    return database_decoded
  else:
    logging.error('\n{}Serato database not found!{}'.format('\033[1;33m', '\033[0m'))
    sys.exit(1)

def DatabaseMusic(serato_folder, database_decoded):
  database_music = []
  database_music_missing = []
  logging.info('{}Extracting song file locations from database'.format('\n\033[1F\033[K'))
  if re.match('/Volumes', serato_folder):
    file_base = serato_folder.split('_Serato_')[0]
  else:
    file_base = '/'
  for line in database_decoded:
    if line[0] == 'otrk':
      file_path = os.path.join(file_base, line[1][1][1])
      if os.path.exists(file_path):
        terminal_width = os.get_terminal_size().columns - 20
        print('Reading {}: {}'.format(len(database_music) + 1, file_path[:terminal_width]), end='\033[K\r')
        database_music.append(file_path)
      else:
        logging.warning('{}MISSING!{} {}'.format('\r\033[K\033[1;33m', '\033[0m', file_path))
        database_music.append(file_path)
        database_music_missing.append(file_path)
  database_music.sort()
  return database_music, database_music_missing

def MusicFolder(database_music):
  print('\r\033[K')
  ### Get all folders from all files in database
  file_folders = set()
  for file in database_music[0]:
    file_folders.add(os.path.dirname(file))
  file_folders = sorted(file_folders)

  commonpath = os.path.commonpath(file_folders)
  if commonpath in file_folders and len(re.findall(commonpath, str(file_folders))) == len(file_folders):
    logging.debug('Music location found: {}'.format(commonpath))
    return commonpath
  else:

    ### Search the parent of all folders and match to previous list
    folder_names = {}
    for path in file_folders:
      for root, dirs, files in os.walk(os.path.dirname(path)):
        if len(dirs) > 1 and re.findall(root, str(file_folders)):
          logging.debug('Found music directory {} with {} subdirectories'.format(root, len(dirs)))
          folder_names.update({root: len(dirs)})

    ### Sort the counts
    folder_names = dict(sorted(folder_names.items(), key=lambda item: item[1], reverse=True))
    logging.debug('Found paths: {}'.format(folder_names))

    folder_check = []
    for found_folder in folder_names:
      folder_check.append(found_folder)

    if folder_check[0] == os.path.commonpath(folder_check):
      logging.debug('Music location found: {}'.format(folder_check[0]))
      return list(folder_names)[0]
    else:
      return SelectMusicFolder(folder_names)

### Change music root to sync
def SelectMusicFolder(folders):
  logging.info('Top {} music locations shown (from Serato database)'.format(len(folders)))
  print('\nSelect music folder to sync as subcrates\n')
  for number, path in enumerate(folders):
    print(' {}. {}'.format(number + 1, path))
  print('\n {}. Select a new path'.format(len(folders) + 1))
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
  print()
  if menu > 0 and menu <= len(folders):
    return(list(folders)[menu - 1])
  elif menu == len(folders) + 1:
    import tkinter
    from tkinter import filedialog
    root = tkinter.Tk()
    root.withdraw()
    logging.info('Select a folder to sync using the file chooser')
    time.sleep(3)
    return filedialog.askdirectory()

def ShowInfo(serato_folder, config, log_location, database_music):
  logging.info('{}Serato Database: {}'.format('\r\033[K', serato_folder))
  config_location = os.path.join(serato_folder, 'Logs', 'SeratoCrateFolderSync.ini')
  logging.info('Configuration File: {}'.format(config_location))
  logging.info('Log File: {}'.format(log_location))
  include_parent_crate = config['crates']['include_parent_crate']
  logging.info('\nDatabase Files: {}'.format(len(database_music[0])) if len(database_music[1]) == 0 else '\nDatabase Files: {} ({} Missing)'.format(len(database_music[0]), len(database_music[1])))
  logging.info('\nInclude Parent Folder as Crate:  {}'.format('YES' if include_parent_crate == 'True' else 'NO'))

def MusicFolderObjects(music_folder, config):
  logging.info('\nMusic Folder: {}'.format(music_folder))
  music_folder_files = []
  music_folder_folders = []
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

### Backup existing database
def BackupDatabase(serato_folder):
  try:
    now = datetime.now()
    backup_folder_now = serato_folder + 'Backups/' + '_Serato_{}{}{}-{}{}{}'.format(now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute), '{:02d}'.format(now.second))
    print()
    logging.info('Backing up database at {} to {}'.format(serato_folder, backup_folder_now))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
    shutil.copytree(serato_folder, backup_folder_now, ignore=copy_ignore, symlinks=True)
    logging.info('{}Backup done!{}'.format('\033[1;32m', '\033[0m'))
  except:
    logging.exception('Error backing up database')

def MakeTempDatabase(serato_folder):
  try:
    tempdir = os.path.join(serato_folder + 'Temp')
    logging.debug('Create temporary database at {}'.format(tempdir))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
    if os.path.exists(tempdir):
      logging.warning('Removing existing temporary database at {}'.format(tempdir))
      shutil.rmtree(tempdir)
    shutil.copytree(serato_folder, tempdir, ignore=copy_ignore, symlinks=True)
    return(tempdir)
  except:
    logging.exception('We ran into a problem at make_temp_database')

### Restore database backup
def RestoreDatabase(backup_folder, serato_folder):
  if os.path.exists(backup_folder):
    backups = []
    for backup in os.listdir(backup_folder):
      full_path = os.path.join(backup_folder, backup)
      if os.path.isdir(full_path):
        backups.append(full_path)
    if len(backups) > 0:
      logging.info('\nRestore from backup\n')
      backups.sort()
      for number, path in enumerate(backups):
        print(' {}. {}'.format(number + 1, path))
      while True:
        menu = input('\nSelect a backup to restore: ')
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
      if menu > 0 and menu <= len(backups):
        print(backups[menu - 1])
        restore_folder = backups[menu - 1]
        if os.path.exists(restore_folder):
          answer = str(input('\nEnter [y]es to backup current database and restore\n {}: '.format(restore_folder)).lower())
          if re.match('y|yes', answer):
            try:
              BackupDatabase(serato_folder)
              # subcrates_path = os.path.join(serato_folder, 'Subcrates')
              # logging.debug('Restore: Removing subcrates folder {}'.format(subcrates_path))
              # shutil.rmtree(subcrates_path)
              logging.info('Restoring from backup: {}'.format(restore_folder))
              copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
              shutil.copytree(restore_folder, serato_folder, ignore=copy_ignore, symlinks=True, dirs_exist_ok=True)
              logging.info('{}Restore done!{}'.format('\033[1;32m', '\033[0m'))
            except:
              logging.error('{}Error restoring database{}'.format('\033[1;33m', '\033[0m'))
          else:
            logging.warning('\nNOPE')
      else:
        pass
  else:
    logging.error('{}Backup folder not found{}'.format('\033[1;33m', '\033[0m'))
    time.sleep(1)
  Header()
  Main()

def ReplacePathFind(music_folder):
  logging.info('\n\n Music folder is: {}'.format(music_folder))
  a = str(input('\n Enter the portion of the path to replace: '))
  if len(a) > 1 and re.search(a, music_folder):
    return a
  elif len(a) == 0:
    logging.warning('Nope')
    return
  else:
    logging.error('Invalid input')
    time.sleep(1)
    ReplacePathFind(music_folder)

def ReplacePath(serato_folder, database_decoded, database_music):
  temp_database = MakeTempDatabase(serato_folder)
  music_folder = MusicFolder(database_music)
  find = ReplacePathFind(music_folder)
  if len(find) == 0:
    Header()
    Main()
  else:
    replace = str(input(' Enter the new replacement portion: '))
    output = []
    l = 0
    for item in database_decoded:
      key = item[0]
      if key == 'otrk':
        otrk_data = []
        otrk_item = item[1]
        for item in otrk_item:
          if item[0] == 'pfil':
            pfil_value = re.sub(find, replace, item[1])
            l = l + 1
            logging.info('Replacing {}: {}'.format(l, pfil_value))
            otrk_data.append((item[0], pfil_value))
          else:
            otrk_data.append(item)
        output.append((key, otrk_data))
      else:
        output.append(item)
    encoded_db = Encode(output)
    temp_database_file = os.path.join(temp_database, 'database V2')
    logging.info('Writing updates: ' + temp_database_file)
    with open(temp_database_file, 'w+b') as new_db:
      new_db.write(encoded_db)
    menu = str(input('\nEnter [y]es to apply changes: ').lower())
    if re.match('y|yes', menu.lower()):
      BackupDatabase(serato_folder)
      ApplyChanges(serato_folder, temp_database)
      logging.info('{}Replace done!{}'.format('\033[1;32m', '\033[0m'))
      time.sleep(1)
    else:
      logging.info('\n{}Not applying changes!{}'.format('\033[1;33m', '\033[0m'))
      time.sleep(2)

### Move temp database to Serato database location
def ApplyChanges(serato_folder, temp_database):
  try:
    logging.info('Moving temp database {} to {}'.format(temp_database, serato_folder))
    copy_ignore = shutil.ignore_patterns('DJ.INFO')
    shutil.copytree(temp_database, serato_folder, dirs_exist_ok=True, symlinks=True, ignore=copy_ignore)
  except:
    logging.exception('Error moving database')

def SyncCrates(serato_folder, music_folder, config, rebuild):
  temp_database = MakeTempDatabase(serato_folder)
  # music_folder = MusicFolder(database_music)
  crate_check = CrateCheck(temp_database, music_folder, config, rebuild)
  if crate_check > 0:
    logging.info('{} crate{} updated'.format(crate_check, 's' if crate_check > 1 else ''))
    menu = str(input('\nEnter [y]es to apply changes: ').lower())
    if re.match('y|yes', menu.lower()):
      BackupDatabase(serato_folder)
      ApplyChanges(serato_folder, temp_database)
      logging.info('{}Sync done!{}'.format('\033[1;32m', '\033[0m'))
      time.sleep(1)
    else:
      print()
      logging.info('Not applying changes')
      time.sleep(2)
      Header()
      Main()
  else:
    logging.info('\033[K\r\033[1;32mNo crate updates required\033[0m')
    time.sleep(1)
    Header()
    Main()
  if os.path.exists(temp_database):
    logging.debug('Removing temporary database at {}'.format(temp_database))
    shutil.rmtree(temp_database)

### Check for existing crate, add if needed
def CrateCheck(temp_database, music_folder, config, rebuild):
  updates = 0
  include_parent_crate = config['crates']['include_parent_crate']
  music_subfolders = []
  for root, dirs, files in os.walk(music_folder):
      if include_parent_crate == 'True':
        music_subfolders.append(root)
      else:
        for dir in dirs:
          music_subfolders.append(os.path.join(root, dir))
      music_subfolders.sort()
  for music_subfolder in music_subfolders:
    logging.debug('Music subfolder: {}'.format(music_subfolder))
    if include_parent_crate == 'True':
      crate_name = music_subfolder.replace(music_folder, os.path.basename(music_subfolder)).replace('/', '%%') + '.crate'
    else:
      crate_name = music_subfolder.replace(music_folder, '')[1:].replace('/', '%%') + '.crate'
    crate_path = os.path.join(temp_database, 'Subcrates', crate_name)
    if os.path.exists(crate_path):
      if rebuild == 'True':
        logging.info('Rebuilding crate: {}'.format(crate_path))
        os.remove(crate_path)
        updates += BuildCrate(crate_path, music_subfolder)
      else:
        logging.debug('{}Crate exists: {}'.format('\033[1F\033[K', crate_path))
        updates += ExistingCrate(crate_path, music_subfolder)
    else:
      logging.info('Crate does not exist: {}'.format(crate_path))
      updates += BuildCrate(crate_path, music_subfolder)
  return updates

def ExistingCrate(crate_path, music_subfolder):
  with open(crate_path, 'rb') as f:
    crate_binary = f.read()
  crate_decoded = DecodeBinary(crate_binary)
  crate_length = len(crate_decoded)
  crate_files = []
  for line in crate_decoded:
    key = line[0]
    if key == 'otrk':
      crate_files.append(line[1][0][1])
  crate_name = os.path.split(crate_path)[-1]
  for file in sorted(os.listdir(music_subfolder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_subfolder):
        music_root = os.path.split(crate_path)[0]
        file_path = os.path.join(music_subfolder.replace(music_root, '')[1:], file)
        #file_full_path = os.path.join(music_root, file_path)
      else:
        file_path = os.path.join(music_subfolder, file)[1:]
        #file_full_path = '/' + file_path
      if file_path not in crate_files:
        logging.info('Adding {} to {}'.format(file_path, crate_name.replace('%%', u' \u2771 ')))
        crate_decoded.append(('otrk', [('ptrk', file_path)]))
        # Minor note to remember I removed the lines to check file against database for stdout (existing vs new file)
  if len(crate_decoded) > crate_length:
    crate_encoded = Encode(crate_decoded)
    with open(crate_path, 'w+b') as new_crate:
      new_crate.write(crate_encoded)
    return 1
  else:
    return 0

### Build a new crate from scratch
def BuildCrate(crate_path, music_subfolder):
  crate_name = os.path.split(crate_path)[-1]
  crate_data = []
  crate_data.append(('vrsn', '1.0/Serato ScratchLive Crate'))
  crate_data.append(('osrt', [('tvcn', 'bpm')]))
  crate_data.append(('ovct', [('tvcn', 'song')], ('ovct', [('tvcn', 'artist')]), ('ovct', [('tvcn', 'bpm')]), ('ovct', [('tvcn', 'key')]), ('ovct', [('tvcn', 'year')]), ('ovct', [('tvcn', 'added')])))
  for file in sorted(os.listdir(music_subfolder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_subfolder):
        music_root = os.path.split(crate_path)[0]
        file_path = os.path.join(music_subfolder.replace(music_root, '')[1:], file)
        #file_full_path = os.path.join(music_root, file_path)
      else:
        file_path = os.path.join(music_subfolder[1:], file)
        #file_full_path = '/' + file_path
      logging.info('Adding {} to {}'.format(file_path, crate_name.replace('%%', u' \u2771 ')))
      crate_data.append(('otrk', [('ptrk', file_path)]))
  crate_binary = Encode(crate_data)
  with open(crate_path, 'w+b') as crate_file:
    crate_file.write(crate_binary)
  return 1



### Not in use - experimental
def Export(database_decoded):
  export = []
  for d in database_decoded[:5]:
    if d[0] == 'otrk':
      filepath = d[1][1][1]
      title = d[1][2][1]
      artist = d[1][3][1]
      album = d[1][4][1]
      genre = d[1][5][1]
      length = d[1][6][1]
      size = d[1][7][1]
      bitrate = d[1][8][1]
      bpm = d[1][9][1]
      comment = d[1][10][1]
      year = d[1][11][1]
      date_added = d[1][12][1]
      key = d[1][13][1]
      columns = [filepath, title, artist, album, genre, length, size, bitrate, bpm, comment, year, date_added, key]
      columns_joined = '\t'.join(columns)
      export.append(columns_joined, '\n')



def Help():
  print('\n\033[1mSerato Crate Folder Sync'+ '\033[0m\n\n\tThis tool allows you to take a folder of music and create crates/subcrates in Serato DJ.\n')
  print('\n\033[1mHow does it work?\033[0m\n\n\tThis program will create new or update existing crate files in _Serato_/Subcrates with the music folder\n\tyou choose.\n\n\tYour database V2 file is scanned to find folders where your music is located.\n\n\tNew files are added to _Serato_/Subcrates/*.crate files. These changes are picked up by Serato DJ and added to \n\tyour database by Serato DJ.')
  print('\n\033[1mOptions\033[0m\n')
  print('\tB\tBackup your _Serato_ database to a _Serato_Backups folder. Note: This will not backup any recordings.\n')
  print('\tD\tChange to another _Serato_ database folder (only available when multiple databases found - usually with \n\t\tinternal and external drives).\n')
  print('\tM\tSet the folder where the music is you want to add to Serato.\n')
  print('\tP\tSet parent folder as a parent crate. This is useful for external drives; it keeps the crates on the external \n\t\tseparate from internal crates.\n')
  print('\tX\tRebuild subcrates will overwrite existing crate files with the music found in the selected folders.\n')
  print('\tS\tSynchronize your music folders to Serato crates. It will display the actions it will take a prompt you before \n\t\tapplying changes. Before applying changes, a backup of your existing _Serato_ folder will be taken.\n')
  print('\n\033[1mAdditional Information\033[0m\n')
  print('\tLogs\tLog files are stored in the _Serato_/Logs folder. They contain additional information for troubleshooting.\n')
  input('\n\nPress any key to continue')
  Main()

if __name__ == '__main__':
  if os.name == 'posix':
    Header()
    Main()
