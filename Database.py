import os, logging, shutil, re, time, eyed3
from datetime import datetime
import Select


def Find():
  """Find/Select Serato databases"""
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
  elif len(serato_databases) > 1:
    return Select.Item(serato_databases)
  else:
    return home_dir_database


class Temp:
  def Create(database):
    database_folder = database['folder']
    """Copy database and work against a temporary copy"""
    self = database_folder + 'Temp'
    logging.debug(f'\033[96mCreate temporary database\033[0m: {self}')
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
    Temp.Remove(self)
    shutil.copytree(database_folder, self, ignore=copy_ignore, symlinks=True)
    return self

  def Remove(self):
    """Clean up temp database"""
    if os.path.exists(self):
      logging.info(f'\033[96mRemoving temporary database\033[0m: {self}')
      shutil.rmtree(self)


def Backup(database):
  database_folder = database['folder']
  """Back up database"""
  backup_folder = database_folder + 'Backups'
  backup_folder_now = f'{backup_folder}/_Serato_{datetime.now().strftime("%Y%m%d-%H%M%S")}'
  print()
  logging.info(f'\033[96mBacking up database\033[0m: {database_folder} to {backup_folder_now}')
  copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
  shutil.copytree(database_folder, backup_folder_now, ignore=copy_ignore, symlinks=True)
  logging.info(f'\033[92mBackup done!\033[0m')


def Restore(database):
  database_folder = database['folder']
  """Restore backup from database"""
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
            Backup(database_folder)
            logging.info(f'Restoring from backup: {restore_folder}')
            copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
            shutil.copytree(restore_folder, database_folder, ignore=copy_ignore, symlinks=True, dirs_exist_ok=True)
            logging.info(f'\033[92mRestore done!\033[0m')
          except:
            logging.error(f'\033[93mError restoring database\033[0m')
        else:
          logging.warning(f'\n\033[93mNOPE\033[0m')


def Apply(database):
  temp_database = database['temp']
  database_folder = database['folder']
  """Apply changes"""
  menu = str(input('\033[K\nEnter [y]es to apply changes: ').lower())
  if re.match('y|yes', menu.lower()):
    Backup(database)
    logging.info(f'Moving temp database: {temp_database} to {database_folder}')
    copy_ignore = shutil.ignore_patterns('DJ.INFO')
    shutil.copytree(temp_database, database_folder, dirs_exist_ok=True, symlinks=True, ignore=copy_ignore)
    return True
  else:
    logging.info(f'\033[93mNot applying changes!\033[0m')
    return False


def CheckTags(database):
  database_folder = database['folder']
  database_decoded = database['decoded']
  """Check ID3 tags against Serato database"""
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
