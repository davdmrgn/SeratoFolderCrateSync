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

def Header():
  print()
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')
  print()

### Search disks for Serato databases
def SearchDatabase():
  # print('Searching for Serato database')
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
  return(serato_databases)

### Select a database if more than one exists
def SelectDatabase(serato_databases):
  if len(serato_databases) == 1:
    # print('Serato database found: {}'.format(serato_databases[0]))
    # time.sleep(1.5)
    return(serato_databases[0])
  elif len(serato_databases) > 1:
    print('{} Serato databases found'.format(len(serato_databases)))
    print()
    for number, path in enumerate(serato_databases):
      print('{}. {}'.format(number + 1, path))
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
  else:
    logging.error('Serato database not found')
    time.sleep(1)

### Logging
def StartLogging():
  now = datetime.now()
  global logfile
  logfile = '{}/Logs/SeratoCrateFolderSync-{}{}{}.log'.format(database, str(now.year), '{:02d}'.format(now.month), '{:02d}'.format(now.day))
  logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger('').addHandler(console)
  logging.debug('Session start')

### Find music location from Serato database
def FindMusic():
  serato_database = os.path.join(database, 'database V2')
  if os.path.exists(serato_database):
    print('Reading Serato database for music location(s)')
    with open(serato_database, 'rb') as db:
      db_binary = db.read()
    db = Decode(db_binary)
    if re.match('/Volumes', serato_database):
      file_base = serato_database.split('_Serato_')[0]
    else:
      file_base = '/'
    global files
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
        logging.debug('Music location found: {}'.format(os.path.normpath(music_paths[0])))
        #time.sleep(1.5)
        return(os.path.normpath(music_paths[0]))
      elif len(music_paths) > 1:
        logging.info('{} Music locations found'.format(len(music_paths)))
        return(SelectMusicPath(os.path.normpath(music_paths[0])))
        #time.sleep(1.5)
      else:
        logging.error('Music location(s) not found')
        time.sleep(1)

### Change music root to sync
def SelectMusicPath(music_paths):
  print()
  print('Select music path')
  print()
  for number, path in enumerate(music_paths):
    print('  {}. {}'.format(number + 1, path))
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
  if menu > 0 and menu <= len(music_paths):
    return(music_paths[menu - 1])

def StartApp():
  Header()
  print()
  if os.path.exists(database):
    logging.info('Serato database:  ' + database)
  else:
    logging.error('Serato database:  ' + 'NOT FOUND')
  if os.path.exists(music):
    logging.info('Music location:  ' + music)
  else:
    logging.error('Music location:  ' + 'NOT FOUND')
  if os.path.exists(config_location):
    logging.info('Configuration file:  ' + config_location)
  else:
    logging.error('Configuration file:  ' + 'NOT FOUND')
  if os.path.exists(logfile):
    logging.info('Log file:  ' + logfile)
  else:
    logging.error('Log file:  ' + 'NOT FOUND')
  print()
  logging.info('Include parent folder as crate:  {}'.format('ENABLED' if include_parent_crate == 'True' else 'DISABLED'))
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
  MainMenu(folder_count, file_count)

def MainMenu(folder_count, file_count):
  print()
  print('B. Back up database')
  serato_database_count = SearchDatabase()
  if len(serato_database_count) > 1:
    print('D. Change _Serato_ database ({} found)'.format(len(serato_database_count)))
  print('M. Change music sync location')
  print('P. {} include parent folder as crate'.format('Disable' if include_parent_crate == 'True' else 'Enable'))
  backup_folder = os.path.join(database + 'Backups')
  if os.path.exists(backup_folder):
    print('R. Restore database from backup')
  print()
  if database and music and len(folder_count) > 1 and len(file_count) > len(folder_count):
    print('S. Synchronize music folders to Serato crates')
    print('X. Rebuild subcrates from scratch')
    print()
  print('H. Help')
  print()
  print('Q. Quit')
  menu = str(input('\nSelect an option: ').lower())
  global rebuild
  if menu == 's':
    rebuild = 'False'
    SyncCrates()
  elif menu == 'x':
    rebuild = 'True'
    SyncCrates()
  elif menu == 'm':
    ChangeMusicLocation(music)
  elif menu == 'p':
    ToggleParentFolderAsCrate(include_parent_crate)
  elif menu == 'b':
    BackupDatabase()
    StartApp()
  elif menu == 'r':
    RestoreDatabase()
  elif menu == 'd':
    ChangeDatabase(database)
  elif menu == 'h':
    Help()
  elif menu == 'q':
    quit()
  else:
    print('Invalid option')
    time.sleep(1)
    StartApp()
  logging.debug('Session end')

def ChangeDatabase(value):
  new_databases = SearchDatabase()
  new_database = SelectDatabase(new_databases)
  if new_database != value:
    global database
    database = new_database
    new_music = FindMusic()
    if new_music:
      global music
      music = new_music
    else:
      ChangeMusicLocation(music)
  StartApp()

def ChangeMusicLocation(value):
  global music
  logging.info('Current Music location:   {}'.format(value))
  value = str(input('\nEnter new music location: '))
  if os.path.exists(value):
    music = value
  else:
    logging.error('New music path not found')
    time.sleep(1)
  StartApp()

def ToggleParentFolderAsCrate(value):
  global include_parent_crate
  if value == 'True':
    include_parent_crate = 'False'
  else:
    include_parent_crate = 'True'
  config.set('crates', 'include_parent_crate', include_parent_crate)
  with open(config_location, 'w') as config_file:
    config.write(config_file)
  StartApp()

### Convert plain text list to binary crate file
def Encode(data):
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
def Decode(data):
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
          value = Decode(binary)
        else:
          value = binary.decode('utf-16-be', errors='ignore')
      i += 8 + length
      result.append((key, value))
    except:
      logging.debug('DECODE ERROR: i: {}, key: {}, length: {}, binary: {}, value: {}'.format(i, key, length, binary, value))
      break
  return(result)

### Copy database to temp folder
def MakeTempDatabase():
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
def MusicFolderScan():
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
def CrateCheck(temp_database, music_folders):
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
        BuildCrate(crate_path, music_folder)
      else:
        logging.debug('Crate exists: {}'.format(crate_path))
        ExistingCrate(crate_path, music_folder)
    else:
      logging.debug('Crate does not exist: {}'.format(crate_path))
      BuildCrate(crate_path, music_folder)

### Build a new crate from scratch
def BuildCrate(crate_path, music_folder):
  global updates
  crate_name = os.path.split(crate_path)[-1]
  logging.info('\nBuilding new crate file {} from path {}'.format(crate_path, music_folder))
  crate_data = b''
  crate_data += Encode([('vrsn', '1.0/Serato ScratchLive Crate')])
  crate_data += Encode([('osrt', [('tvcn', 'song'), ('brev', '')])])
  crate_data += Encode([('ovct', [('tvcn', 'song'), ('tvcw', '0')]), ('ovct', [('tvcn', 'artist'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bpm'), ('tvcw', '0')]), ('ovct', [('tvcn', 'key'), ('tvcw', '0')]), ('ovct', [('tvcn', 'year'), ('tvcw', '0')]), ('ovct', [('tvcn', 'grouping'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bitrate'), ('tvcw', '0')]), ('ovct', [('tvcn', 'undef'), ('tvcw', '0')]), ('ovct', [('tvcn', 'added'), ('tvcw', '0')]), ('ovct', [('tvcn', 'composer'), ('tvcw', '0')]), ('ovct', [('tvcn', 'comment'), ('tvcw', '0')]), ('ovct', [('tvcn', 'location'), ('tvcw', '0')]), ('ovct', [('tvcn', 'filename'), ('tvcw', '0')]), ('ovct', [('tvcn', 'genre'), ('tvcw', '0')]), ('ovct', [('tvcn', 'album'), ('tvcw', '0')]), ('ovct', [('tvcn', 'label'), ('tvcw', '0')])])
  for file in sorted(os.listdir(music_folder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_folder):
        music_root = os.path.split(database)[0]
        file_path = os.path.join(music_folder.replace(music_root, '')[1:], file)
        file_full_path = os.path.join(music_root, file_path)
      else:
        file_path = os.path.join(music_folder[1:], file)
        file_full_path = '/' + file_path
      if file_full_path in files:
        logging.info('Adding existing file {} to {}'.format(file, crate_name.replace('%%', u' \u2771 ')))
      else:
        logging.info('Adding new file {} to {}'.format(file, crate_name.replace('%%', u' \u2771 ')))
      crate_data += Encode([('otrk', [('ptrk', file_path)])])
      updates += 1
  if len(crate_data) > 525:
    with open(crate_path, 'w+b') as crate_file:
      crate_file.write(crate_data)
  pass

### Update existing crate
def ExistingCrate(crate_path, music_folder):
  global updates
  crate_name = os.path.split(crate_path)[-1]
  logging.debug('Checking existing crate - source: {}\tcrate file: {}'.format(music_folder, crate_path))
  with open(crate_path, 'rb') as f:
    crate_data = f.read()
  for file in sorted(os.listdir(music_folder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_folder):
        music_root = os.path.split(database)[0]
        file_path = os.path.join(music_folder.replace(music_root, '')[1:], file)
        file_full_path = os.path.join(music_root, file_path)
      else:
        file_path = os.path.join(music_folder[1:], file)
        file_full_path = '/' + file_path
      file_binary = Encode([('otrk', [('ptrk', file_path)])])
      if crate_data.find(file_binary) != -1:
        #logging.debug('{} exists in crate {}'.format(file, crate_name))
        pass
      else:
        if file_full_path in files:
          logging.info('Adding existing file {} to {}'.format(file, crate_name.replace('%%', u' \u2771 ')))
        else:
          logging.info('Adding new file {} to {}'.format(file, crate_name.replace('%%', u' \u2771 ')))
        with open(crate_path, 'ab') as crate_file:
          crate_file.write(file_binary)
        updates += 1

### Backup existing database
def BackupDatabase():
  try:
    now = datetime.now()
    backup_folder = database + 'Backups/' + '_Serato_{}{}{}-{}{}{}'.format(now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day), '{:02d}'.format(now.hour), '{:02d}'.format(now.minute), '{:02d}'.format(now.second))
    print()
    logging.info('Backing up database at {} to {}'.format(database, backup_folder))
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*')
    shutil.copytree(database, backup_folder, ignore=copy_ignore)
  except:
    logging.exception('Error backing up database')

### Restore database backup
def RestoreDatabase():
  backup_folder = os.path.join(database + 'Backups')
  if os.path.exists(backup_folder):
    backups = []
    for b in os.listdir(backup_folder):
      full_path = os.path.join(backup_folder, b)
      if os.path.isdir(full_path):
        backups.append(full_path)
    if len(backups) > 0:
      print('\nRestore from backup\n')
      backups.sort()
      for number, path in enumerate(backups):
        print('{}. {}'.format(number + 1, path))
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
        restore = backups[menu - 1]
        if os.path.exists(restore):
          answer = str(input('\nEnter [y]es to backup current database and restore\n {}: '.format(restore)).lower())
          if re.match('y|yes', answer):
            try:
              BackupDatabase()
              subcrates_path = os.path.join(database, 'Subcrates')
              logging.debug('Restore: Removing subcrates path {}'.format(subcrates_path))
              shutil.rmtree(subcrates_path)
              logging.info('Restoring from backup: {}'.format(restore))
              shutil.copytree(restore, database, dirs_exist_ok=True)
              logging.info('Restore complete')
            except:
              logging.error('Error in RestoreDatabase')
          else:
            print('\nNOPE')
      else:
        pass
  else:
    logging.error('Backup folder does not exist')
  StartApp()

### Move temp database to Serato database location
def MoveDatabase(temp_database):
  try:
    logging.info('Moving temp database {} to {}'.format(temp_database, database))
    shutil.copytree(os.path.join(temp_database, 'Subcrates'), os.path.join(database, 'Subcrates'), dirs_exist_ok=True)
  except:
    logging.exception('Error moving database')

### Payload
def SyncCrates():
  try:
    global updates
    updates = 0
    global temp_database
    temp_database = MakeTempDatabase()
    music_folders = MusicFolderScan()
    CrateCheck(temp_database, music_folders)
    if updates > 0:
      print()
      logging.info('updates'.format(updates))
      #time.sleep(1)
      menu = str(input('\nEnter [y]es to apply changes: ').lower())
      if menu == 'y':
        BackupDatabase()
        MoveDatabase(temp_database)
      else:
        logging.info('Not applying changes')
    else:
      logging.info('\nNo crate updates required')
    #time.sleep(1)
    logging.debug('Removing temporary database at {}'.format(temp_database))
    shutil.rmtree(temp_database)
  except:
    logging.exception('We ran into a problem at sync_crates')

def Help():
  print('\n' + '\033[1m' + 'Serato Crate Folder Sync'+ '\033[0m' + '\n\n\tThis tool allows you to take a folder of music and create crates/subcrates in Serato DJ.\n')
  print('\n' + '\033[1m' + 'How does it work?' + '\033[0m' + '\n\n\tThis program will create new or update existing crate files in _Serato_/Subcrates with the music folder\n\tyou choose.\n\n\tYour database V2 file is scanned to find folders where your music is located.\n\n\tNew files are added to _Serato_/Subcrates/*.crate files. These changes are picked up by Serato DJ and added to \n\tyour database by Serato DJ.')
  print('\n' + '\033[1m' + 'Options' + '\033[0m' + '\n')
  print('\tB\tBackup your _Serato_ database to a _Serato_Backups folder. Note: This will not backup any recordings.\n')
  print('\tD\tChange to another _Serato_ database folder (only available when multiple databases found - usually with \n\t\tinternal and external drives).\n')
  print('\tM\tSet the folder where the music is you want to add to Serato.\n')
  print('\tP\tSet parent folder as a parent crate. This is useful for external drives; it keeps the crates on the external \n\t\tseparate from internal crates.\n')
  print('\tX\tRebuild subcrates will overwrite existing crate files with the music found in the selected folders.\n')
  print('\tS\tSynchronize your music folders to Serato crates. It will display the actions it will take a prompt you before \n\t\tapplying changes. Before applying changes, a backup of your existing _Serato_ folder will be taken.\n')
  print('\n' + '\033[1m' + 'Additional Information' + '\033[0m' + '\n')
  print('\tLogs\tLog files are stored in the _Serato_/Logs folder. They contain additonal information for troubleshooting.\n')
  input('\n\nPress ENTER to continue')
  StartApp()

### Entrypoint
os.system('clear')
databases = SearchDatabase()
database = SelectDatabase(databases)
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
      config.add_section('crates')
      config.add_section('paths')
      config.set('crates', 'include_parent_crate', include_parent_crate)
      with open(config_location, 'w') as config_file:
        config.write(config_file)
    include_parent_crate = config['crates']['include_parent_crate']

    StartApp()
  else:
    logging.error('Music location not found')
else:
  print('Serato database not found')
