#!/usr/bin/env python3
import os, sys, logging, struct, io, re, time, shutil
import tkinter, configparser, eyed3
from tkinter import filedialog
from datetime import datetime


class Menu:
  def Header():
    print(f'\n╔{"═"*66}╗')
    print(f'║{" "*21}Serato Crate Folder Sync{" "*21}║')
    print(f'╚{"═"*66}╝\n')

  def Print():
    Menu.Info()
    Menu.Options()

  def Info():
    logging.info(f'Serato Database: {database_folder}\033[K')
    logging.info(f'Configuration File: {Config.File()}')
    logging.info(f'Log File: {log}')
    print()
    logging.info(f'Database Files: {len(database_music)}')
    logging.info(f'Missing Files:  {len(database_music_missing)}')
    include_parent_crate = Config.Get('options', 'include_parent_crate', 'False')
    print()
    logging.info(f'Include Parent Folder as Crate: {include_parent_crate}')

  def Options():
    print()
    if database_folder and music_folder and not len(database_music) > len(database_music_missing):
      logging.error(f'\033[91mMore files are missing than exists!?!?!??\033[0m\n')
    print(f'\033[1mS. Synchronize music folders to Serato crates\033[0m\n')
    if config.get('options', 'include_parent_crate') == 'True':
      include_parent_crate_switch = 'Disable'
    else:
      include_parent_crate_switch = 'Enable'
    print(f'P. {include_parent_crate_switch} include parent folder as crate')
    print(f'A. Advanced options')
    print(f'H. Help')
    print(f'\nQ. Quit')
    selection = str(input('\nSelect an option: ').lower())
    Menu.Action(selection)

  def OptionsAdvanced():
    print('\nB. Backup database')
    backup_folder = os.path.join(database_folder + 'Backups')
    if os.path.exists(backup_folder):
      print('R. Restore database from backup')
    print('X. Rebuild subcrates from scratch')
    print('T. Check ID3 tags against database')
    if len(database_music_missing) > 0:
      print('L. Locate lost files')
    print('U. Update music folder path in database')
    selection = str(input('\nSelect an option: ').lower())
    return selection
  
  def Action(selection):
    if selection == 'a':
      selection = Menu.OptionsAdvanced()
      if selection == 'b':
        Database.Backup()
      elif selection == 'r':
        Database.Restore()
        sys.exit(0)
      elif selection == 'x':
        Crate.Sync(rebuild = True)
        sys.exit(0)
      elif selection == 't':
        Database.CheckTags()
      elif selection == 'u':
        ReplacePath.Find()
        sys.exit(0)
      elif selection == 'l':
        LocateLostFiles.Init()
        sys.exit(0)
      elif selection == 'u':
        ReplacePath.Find()
        sys.exit(0)
    elif selection == 's':
      Crate.Sync()
      sys.exit(0)
    elif selection == 'p':
      Config.ToggleOption('options', 'include_parent_crate')
    elif selection == 'h':
      Help()
    elif selection == 'q':
      logging.debug(f'Session end')
      sys.exit(0)
    elif selection == 't':
      print('TEST AREA')
      time.sleep(2)
    else:
      time.sleep(1)


class LocateLostFiles:
  def Init():
    if len(database_music_missing) == 0:
      logging.info('\n\033[92mYou have no missing files in your library\033[0m')
    else:
      print(f'{len(database_music_missing)} missing file(s)')
      temp_database = Database.Temp.Create()
      LocateLostFiles.Search(temp_database)
      Database.Apply(temp_database)
      Database.Temp.Remove(temp_database)

  def Search(temp_database):
    for i, item in enumerate(database_music_missing):
      logging.debug(f'{i}/{len(database_music_missing)} Searching for missing song(): {item}')
      for ii, db_entry in enumerate(database_decoded[1:]):
        if item[1:] == db_entry[1][1][1]:
          logging.debug(f'{i}/{len(database_music_missing)} Missing song location found in database: [{ii + 1}] {item}')
          LocateLostFiles.Compare(ii + 1, temp_database)
          break

  def Compare(ii, temp_database):
    db_entry = database_decoded[ii]
    db_entry_filetype = db_entry[1][0][1]
    db_entry_filepath = db_entry[1][1][1]
    db_entry_filename = os.path.split(db_entry_filepath)[-1]
    db_entry_title = db_entry[1][2][1]
    db_entry_artist = db_entry[1][3][1]
    logging.info(f'\nSearching for missing song in: {music_folder}')
    for root, dirs, files in os.walk(music_folder):
      for file in files:
        if file.endswith(db_entry_filetype):
          file_fullpath = os.path.join(root, file)
          if file_fullpath not in database_music:
            try:
              id3 = eyed3.load(file_fullpath)
              if id3.tag.artist == db_entry_artist and id3.tag.title == db_entry_title:
                print(f'\033[92mFound match by ID3 TAG!\033[0m {file_fullpath}')
                LocateLostFiles.Update(ii, id3, temp_database)
                # Update = True
                break
              elif file == db_entry_filename:
                print(f'\033[92mFound match by FILENAME!\033[0m {file_fullpath}')
                LocateLostFiles.Update(ii, id3, temp_database)
                # Update = True
                break
            except Exception as e:
              logging.error(f'\nProblem reading ID3 tag: {file_fullpath}')
              break

  def Update(db_index, id3, temp_database):
    """Update database"""
    old_pfil = database_decoded[db_index][1][1][1]
    database_decoded[db_index][1][1] = ('pfil', id3.path[1:])
    database_decoded[db_index][1][2] = ('tsng', id3.tag.title)
    database_decoded[db_index][1][3] = ('tart', id3.tag.artist)
    database_decoded[db_index][1][25] = ('bovc', b'\x00')
    database_encoded = SeratoData.Encode(database_decoded)
    temp_database_file = os.path.join(temp_database, 'database V2')
    logging.info('Updating database: ' + temp_database_file)
    with open(temp_database_file, 'w+b') as new_db:
      new_db.write(database_encoded)
    """Update crates"""
    for root, dirs, files in os.walk(temp_database):
      for crate_file in files:
        if crate_file.endswith('crate'):
          crate_fullpath = os.path.join(root, crate_file)
          crate_fullpath_displayname = crate_fullpath.replace('%%', u' \u2771 ')
          logging.debug(f'Scanning {"Smart" if crate_file.endswith(".scrate") else ""}Crate: {crate_fullpath_displayname}\033[K\r')
          crate_binary = SeratoData.Read(crate_fullpath)
          crate_decoded = SeratoData.Decode(crate_binary)
          for line in crate_decoded:
            if old_pfil in str(line[1][0]):
              crate_replaced = SeratoData.Replace(crate_decoded, old_pfil, id3.path[1:])
              crate_replaced_encoded = SeratoData.Encode(crate_replaced)
              logging.info(f'Updating {"Smart" if crate_file.endswith(".scrate") else ""}Crate: ' + crate_fullpath)
              with open(crate_fullpath, 'w+b') as new_data:
                new_data.write(crate_replaced_encoded)


class Database:
  def Find():
    serato_databases = []
    """/Users dir"""
    home_dir = os.path.expanduser('~')
    music_dir = os.path.join(home_dir, 'Music')
    home_dir_database = os.path.join(music_dir, '_Serato_/database V2')
    if os.path.exists(home_dir_database) and os.stat(home_dir_database).st_size > 80:
      serato_databases.append(home_dir_database)
    """/Volumes"""
    volumes = os.listdir('/Volumes')
    for volume in volumes:
      volume_database = os.path.join('/Volumes', volume, '_Serato_/database V2')
      if os.path.exists(volume_database):
        serato_databases.append(volume_database)
    if len(serato_databases) == 1:
      return serato_databases[0]
    else:
      return Select.Item(serato_databases)
    
  class Temp:
    def Create():
      self = database_folder + 'Temp'
      logging.debug(f'\033[96mCreate temporary database\033[0m: {self}')
      copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
      Database.Temp.Remove(self)
      shutil.copytree(database_folder, self, ignore=copy_ignore, symlinks=True)
      return self

    def Remove(self):
      if os.path.exists(self):
        logging.info(f'\033[96mRemoving temporary database\033[0m: {self}')
        shutil.rmtree(self)

  def Backup():
    backup_folder = database_folder + 'Backups'
    backup_folder_now = f'{backup_folder}/_Serato_{datetime.now().strftime("%Y%m%d-%H%M%S")}'
    print()
    logging.info(f'\033[96mBacking up database\033[0m: {database_folder} to {backup_folder_now}')
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
    shutil.copytree(database_folder, backup_folder_now, ignore=copy_ignore, symlinks=True)
    logging.info(f'\033[92mBackup done!\033[0m')

  def Restore():
    backup_folder = database_folder + 'Backups'
    if not os.path.exists(backup_folder):
      logging.error(f'\033[93mBackup folder not found\033[0m')
      time.sleep(1)
    else:
      backups = []
      for backup in os.listdir(backup_folder):
        full_path = os.path.join(backup_folder, backup)
        if os.path.isdir(full_path) and re.match('_Serato_', backup):
          backups.append(full_path)
      if len(backups) == 0:
        logging.error(f'\033[93mNo backups found\033[0m')
        time.sleep(1)
      else:
        logging.info('\nRestore from backup\n')
        backups.sort(reverse=True)
        restore_folder = Select.Item(backups)
        if os.path.exists(restore_folder):
          answer = str(input(f'\nEnter [y]es to backup current database and restore\n {restore_folder}: ').lower())
          if re.match('y|yes', answer):
            try:
              Database.Backup()
              logging.info(f'Restoring from backup: {restore_folder}')
              copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
              shutil.copytree(restore_folder, database_folder, ignore=copy_ignore, symlinks=True, dirs_exist_ok=True)
              logging.info(f'\033[92mRestore done!\033[0m')
            except:
              logging.error(f'\033[93mError restoring database\033[0m')
          else:
            logging.warning(f'\n\033[93mNOPE\033[0m')

  def Apply(temp_database):
    menu = str(input('\nEnter [y]es to apply changes: ').lower())
    if re.match('y|yes', menu.lower()):
      Database.Backup()
      logging.info(f'Moving temp database: {temp_database} to {database_folder}')
      copy_ignore = shutil.ignore_patterns('DJ.INFO')
      shutil.copytree(temp_database, database_folder, dirs_exist_ok=True, symlinks=True, ignore=copy_ignore)
      return True
    else:
      logging.info(f'\033[93mNot applying changes!\033[0m')
      return False

  def CheckTags():
    if re.match('/Volumes', database_folder):
      file_base = database_folder.split('_Serato_')[0]
    else:
      file_base = '/'
    for i, item in enumerate(database_decoded[1:]):
      item_filepath = file_base + item[1][1][1]
      item_title = item[1][2][1]
      item_artist = item[1][3][1]
      if os.path.exists(item_filepath):
        id3 = eyed3.load(item_filepath)
        if item_title != id3.tag.title:
          logging.warning(f'{i}/{len(database_decoded) - 1} \033[93mTitle mismatch!\033[0m DB: {item_title}\t\033[96mID3: {id3.tag.title}\033[0m\tFile: {os.path.split(item_filepath)[-1]}')
        elif item_artist != id3.tag.artist:
          logging.warning(f'{i}/{len(database_decoded) - 1} \033[93mArtist mismatch!\033[0m DB: {item_artist}\t\033[96mID3: {id3.tag.artist}\033[0m\tFile: {os.path.split(item_filepath)[-1]}')
        else:
          print(f'{i}/{len(database_decoded) - 1}', end='\r')
      else:
        logging.error(f'{i}/{len(database_decoded) - 1} \033[93mMISSING!\033[0m {item_filepath}')
    print('\033[K')


class Select:
  def Item(self):
    for i, item in enumerate(self):
      print(f'  {i + 1}. {item}')
    print(f'  {i + 1}. Use file chooser')
    while True:
      selection = int(input('\nSelect an option: '))
      if selection > 0 and selection <= len(self):
        return self[selection - 1]
      elif selection == selection[i + 1]:
        return Select.Directory()

  def Directory():
    root = tkinter.Tk()
    root.withdraw()
    self = filedialog.askdirectory()
    root.destroy()
    return self


def Logger():
  log_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}-{datetime.now().strftime("%Y-%m-%d")}.log'
  log = f'{database_folder}/Logs/{log_filename}'
  logging.basicConfig(filename=log, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger(None).addHandler(console)
  logging.debug('\nSession start')
  return log


class Config:
  def File():
    config_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}.ini'
    config_path = os.path.join(database_folder, 'Logs', config_filename)
    return config_path
  
  def Read():
    config_file = Config.File()
    config = configparser.ConfigParser()
    config.read(config_file)
    return config
  
  def Get(section, option, default_value = ''):
    if not config.has_option(section, option):
      logging.debug(f'Setting {option} to default value: {default_value}')
      Config.Set(section, option, default_value)
    return config.get(section, option)
  
  def Set(section, option, value):
    if not config.has_section(section):
      config.add_section(section)
    config.set(section, option, value)
    config_file = Config.File()
    with open(config_file, 'w') as f:
      config.write(f)
    return config
  
  def ToggleOption(section, option):
    value = Config.Get(section, option)
    if value == 'True':
      Config.Set(section, option, 'False')
    else:
      Config.Set(section, option, 'True')
    return config


class SeratoData:
  def Read(self):
    print(f'Reading Serato {"crate" if self.endswith("crate") else "database"} file: {self}', end='\033[K\r')
    with open(self, 'rb') as data:
      binary = data.read()
    return binary
  
  def Decode(self):
    output = []
    i = 0
    while i < len(self):
      a = i + 4
      b = a + 4
      key_binary = self[i:a]
      key = key_binary.decode('utf-8')
      length_binary = self[a:b]
      length = struct.unpack('>I', length_binary)[0]
      value_binary = self[b:b + length]
      if re.match('^o', key):
        value = SeratoData.Decode(value_binary)
        if len(value) > 2:
          value_str = value[1][1]
        elif len(value) == 1:
          value_str = value[0][1]
        else:
          value_str = value
        print(f'Decoding {len(output)}: {value_str[:terminal_width]}', end='\033[K\r')
      elif re.match('(?!^u|^s|^b|^r)' , key):
        value = value_binary.decode('utf-16-be')
      else:
        value = value_binary
      output.append((key, value))
      i += 8 + length
    # print('Decode complete', end='\033[K\r')
    return output

  def Encode(self):
    output = io.BytesIO()
    for i, line in enumerate(self):
      key = line[0]
      key_binary = key.encode('utf-8')
      if key == 'vrsn':
        value = line[1]
        value_binary = value.encode('utf-16-be')
      elif re.match('^o', key):
        o_values = line[1]
        if len(o_values) > 2:
          print(f'Encoding {i}: {o_values[1][1][:terminal_width]}', end='\033[K\r')
        elif len(o_values) == 1:
          print(f'Encoding {i}: {o_values[0][1][:terminal_width]}', end='\033[K\r')
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
    print('Encode complete', end='\033[K\r')
    return output.getvalue()
  
  def Replace(self, find, replace):
    output = []
    for i, item in enumerate(self):
      key = item[0]
      if key == 'otrk':
        otrk_data = []
        otrk_item = item[1]
        for item in otrk_item:
          if re.match('pfil|ptrk', item[0]) and find in item[1]:
            p_value = item[1].replace(find, replace)
            logging.info(f'Replacing {i}: {p_value[:terminal_width]}')
            otrk_data.append((item[0], p_value))
          else:
            otrk_data.append(item)
        output.append((key, otrk_data))
      else:
        output.append(item)
    return output


class Music:
  def Extract(self):
    database_music = []
    database_music_missing = []
    # print()
    logging.info(f'Extracting song file locations from database\033[K')
    if re.match('/Volumes', database_folder):
      file_base = database_folder.split('_Serato_')[0]
    else:
      file_base = '/'
    for line in self:
      if line[0] == 'otrk':
        file_path = os.path.join(file_base, line[1][1][1])
        if os.path.exists(file_path):
          print(f'Found {len(database_music) + 1}: {file_path[:terminal_width]}', end='\033[K\r')
          database_music.append(file_path)
        else:
          logging.warning(f'\033[93mMISSING!\033[0m {file_path}\033[K')
          database_music.append(file_path)
          database_music_missing.append(file_path)
    return database_music, database_music_missing

  def Folder(self):
    """Get all folders from files in database"""
    print('Finding music folder from files in database\033[K')
    file_folders = set()
    for file in self:
      """Exclude recordings in _Serato_ folder"""
      if database_folder not in file:
        print(os.path.dirname(file), end='\033[K\r')
        file_folders.add(os.path.dirname(file))
    print('\033[K')
    file_folders = sorted(file_folders)
    commonpath = os.path.commonpath(file_folders)
    if commonpath in file_folders and len(re.findall(commonpath, str(file_folders))) == len(file_folders):
      logging.info(f'Music location: {commonpath}')
      return commonpath
    else:
      """Search the parent of all folders and match to previous list"""
      folder_names = {}
      for path in file_folders:
        for root, dirs, files in os.walk(os.path.dirname(path)):
          if len(dirs) > 1 and re.findall(root, str(file_folders)):
            logging.debug(f'Found music directory {root} with {len(dirs)} subdirectories')
            folder_names.update({root: len(dirs)})

      """Sort the counts"""
      folder_names = dict(sorted(folder_names.items(), key=lambda item: item[1], reverse=True))
      logging.debug(f'Found paths: {folder_names}')

      folder_check = []
      for found_folder in folder_names:
        folder_check.append(found_folder)

      if folder_check[0] == os.path.commonpath(folder_check):
        logging.debug(f'Music location found: {folder_check[0]}')
        return list(folder_names)[0]
      else:
        return Select.Item(folder_names)


class Crate:
  def Sync(rebuild = False):
    temp_database = Database.Temp.Create()
    crate_check = Crate.Check(temp_database, rebuild)
    if crate_check > 0:
      logging.info(f'{crate_check} crate{"s" if crate_check > 1 else ""} to update\033[K')
      apply = Database.Apply(temp_database)
      if apply == True:
        logging.info(f'\033[92mSync done!\033[0m')
    elif crate_check == 0:
      logging.info(f'\033[K\r\033[92mNo crate updates required\033[0m')
    time.sleep(1)
    Database.Temp.Remove(temp_database)

  def Check(temp_database, rebuild):
    updates = 0
    music_subfolders = []
    for root, dirs, files in os.walk(music_folder):
      include_parent_crate = Config.Get('options', 'include_parent_crate')
      if include_parent_crate == 'True':
        music_subfolders.append(root)
      else:
        for dir in dirs:
          music_subfolders.append(os.path.join(root, dir))
    music_subfolders.sort()
    for music_subfolder in music_subfolders:
      logging.debug(f'Music subfolder: {music_subfolder}')
      if config.get('options', 'include_parent_crate') == 'True':
        crate_name = music_subfolder.replace(music_folder, os.path.basename(music_subfolder)).replace('/', '%%') + '.crate'
      else:
        crate_name = music_subfolder.replace(music_folder, '')[1:].replace('/', '%%') + '.crate'
      crate_path = os.path.join(temp_database, 'Subcrates', crate_name)
      if os.path.exists(crate_path):
        if rebuild == True:
          logging.info(f'\033[93mRebuilding crate:\033[0m {crate_path}')
          os.remove(crate_path)
          updates += Crate.Build(crate_path, music_subfolder)
        else:
          logging.debug(f'\033[1F\033[KCrate exists: {crate_path}')
          updates += Crate.Existing(crate_path, music_subfolder)
      else:
        logging.info(f'Crate does not exist: {crate_path}')
        updates += Crate.Build(crate_path, music_subfolder)
    return updates

  def Existing(crate_path, music_subfolder):
    with open(crate_path, 'rb') as f:
      crate_binary = f.read()
    crate_data = SeratoData.Decode(crate_binary)
    crate_length = len(crate_data)
    crate_files = []
    for line in crate_data:
      key = line[0]
      if key == 'otrk':
        crate_files.append(line[1][0][1])
    crate_name = os.path.split(crate_path)[-1]

    Crate.Scan(music_subfolder, crate_name, crate_data, crate_path, crate_files)

    if len(crate_data) > crate_length:
      crate_encoded = SeratoData.Encode(crate_data)
      with open(crate_path, 'w+b') as new_crate:
        new_crate.write(crate_encoded)
      return 1
    else:
      return 0

  def Build(crate_path, music_subfolder):
    crate_name = os.path.split(crate_path)[-1]
    crate_data = []
    crate_data.append(('vrsn', '1.0/Serato ScratchLive Crate'))
    crate_data.append(('osrt', [('tvcn', 'bpm')]))
    crate_data.append(('ovct', [('tvcn', 'song')], ('ovct', [('tvcn', 'artist')]), ('ovct', [('tvcn', 'bpm')]), ('ovct', [('tvcn', 'key')]), ('ovct', [('tvcn', 'year')]), ('ovct', [('tvcn', 'added')])))

    Crate.Scan(music_subfolder, crate_name, crate_data, crate_path)

    crate_binary = SeratoData.Encode(crate_data)
    with open(crate_path, 'w+b') as crate_file:
      crate_file.write(crate_binary)
    return 1

  def Scan(music_subfolder, crate_name, crate_data, crate_path, crate_files = []):
    for file in sorted(os.listdir(music_subfolder)):
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        if re.match('/Volumes', music_subfolder):
          music_root = os.path.split(crate_path)[0]
          file_path = os.path.join(music_subfolder.replace(music_root, '')[1:], file)
          file_full_path = os.path.join(music_root, file_path)
        else:
          file_path = os.path.join(music_subfolder[1:], file)
          file_full_path = '/' + file_path
        if file_path not in crate_files:
          if file_full_path in database_music:
            file_status = 'existing'
          else:
            file_status = 'new'
          crate_name_displayname = crate_name.replace('%%', u' \u2771 ')
          logging.info(f'Adding {file_status} file {file_full_path} to {crate_name_displayname}')
          crate_data.append(('otrk', [('ptrk', file_path)]))

class ReplacePath:
  def Find():
    logging.info(f'\n\n Music folder is: {music_folder}')
    while True:
      find = str(input('\n Enter the portion of the path to replace: '))
      if len(find) > 1 and re.search(find, music_folder):
        replace = str(input(' Enter the new replacement portion: '))
        ReplacePath.Replace(find, replace)
      else:
        logging.warning('Nope')
        time.sleep(1)
      break

  def Replace(find, replace):
    temp_database = Database.Temp.Create()
    """Database"""
    database_replaced = SeratoData.Replace(database_decoded, find, replace)
    database_replaced_encoded = SeratoData.Encode(database_replaced)
    temp_database_file = os.path.join(temp_database, 'database V2')
    logging.info('Updating database: ' + temp_database_file)
    with open(temp_database_file, 'w+b') as new_db:
      new_db.write(database_replaced_encoded)
    """Crates"""
    for root, dirs, files in os.walk(temp_database):
      for crate_file in files:
        if crate_file.endswith('crate'):
          crate_fullpath = os.path.join(root, crate_file)
          crate_fullpath_displayname = crate_fullpath.replace('%%', u' \u2771 ')
          logging.debug(f'Scanning {"Smart" if crate_file.endswith(".scrate") else ""}Crate: {crate_fullpath_displayname}')
          crate_binary = SeratoData.Read(crate_fullpath)
          crate_decoded = SeratoData.Decode(crate_binary)
          crate_replaced = SeratoData.Replace(crate_decoded, find, replace)
          crate_replaced_encoded = SeratoData.Encode(crate_replaced)
          logging.debug('Updating Crate: ' + crate_fullpath)
          with open(crate_fullpath, 'w+b') as new_data:
            new_data.write(crate_replaced_encoded)
    Database.Apply(temp_database)
    Database.Temp.Remove(temp_database)


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


if __name__ == '__main__':
  if os.name == 'posix':
    Menu.Header()
    terminal_width = os.get_terminal_size().columns - 20
    eyed3.log.setLevel('ERROR') # Change this to DEBUG when troubleshooting tags
    database = Database.Find()
    database_folder = os.path.dirname(database)
    log = Logger()
    config = Config.Read()
    database_binary = SeratoData.Read(database)
    database_decoded = SeratoData.Decode(database_binary)
    database_music, database_music_missing = Music.Extract(database_decoded)
    music_folder = Music.Folder(database_music)
    while True:
      menu_input = Menu.Print()
      Menu.Action(menu_input)
  else:
    print('macOS only right now')
