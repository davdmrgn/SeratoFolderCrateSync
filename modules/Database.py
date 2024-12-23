import os, logging, shutil, re, time, eyed3, csv
from datetime import datetime
from modules import Select


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
  def Create(data):
    db_path = data['db_path']
    """Copy database and work against a temporary copy"""
    self = db_path + 'Temp'
    logging.debug(f'\033[96mCreate temporary database\033[0m: {self}')
    copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
    Temp.Remove(self)
    shutil.copytree(db_path, self, ignore=copy_ignore, symlinks=True)
    return self

  def Remove(self):
    """Clean up temp database"""
    if os.path.exists(self):
      logging.info(f'\033[96mRemoving temporary database\033[0m: {self}')
      shutil.rmtree(self)


def Backup(data):
  db_path = data['db_path']
  """Back up database"""
  backup_path = db_path + 'Backups'
  backup_path_now = f'{backup_path}/_Serato_{datetime.now().strftime("%Y%m%d-%H%M%S")}'
  print()
  logging.info(f'\033[96mBacking up database\033[0m: {db_path} to {backup_path_now}')
  copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
  shutil.copytree(db_path, backup_path_now, ignore=copy_ignore, symlinks=True)
  logging.info(f'\033[92mBackup done!\033[0m')


def Restore(data):
  db_path = data['db_path']
  """Restore backup from database"""
  backup_path = db_path + 'Backups'
  if not os.path.exists(backup_path):
    logging.error(f'\033[93mBackup folder not found\033[0m')
    time.sleep(1)
  else:
    backups = []
    for backup in os.listdir(backup_path):
      full_path = os.path.join(backup_path, backup)
      if os.path.isdir(full_path) and re.match('_Serato_', backup):
        backups.append(full_path)
    if len(backups) == 0:
      logging.error(f'\033[93mNo backups found\033[0m')
      time.sleep(1)
    else:
      logging.info('\nRestore from backup\n')
      backups.sort(reverse=True)
      restore_path = Select.Item(backups)
      if os.path.exists(restore_path):
        answer = str(input(f'\nEnter [y]es to backup current database and restore\n {restore_path}: ').lower())
        if re.match('y|yes', answer):
          try:
            Backup(db_path)
            logging.info(f'Restoring from backup: {restore_path}')
            copy_ignore = shutil.ignore_patterns('.git*', 'Recording*', 'DJ.INFO')
            shutil.copytree(restore_path, db_path, ignore=copy_ignore, symlinks=True, dirs_exist_ok=True)
            logging.info(f'\033[92mRestore done!\033[0m')
          except:
            logging.error(f'\033[93mError restoring database\033[0m')
        else:
          logging.warning(f'\n\033[93mNOPE\033[0m')


def Apply(data):
  temp_database = data['db_temp']
  db_path = data['db_path']
  """Apply changes"""
  menu = str(input('\033[K\nEnter [y]es to apply changes: ').lower())
  if re.match('y|yes', menu.lower()):
    Backup(data)
    logging.info(f'\033[96mMoving temp database\033[0m: {temp_database} to {db_path}')
    copy_ignore = shutil.ignore_patterns('DJ.INFO')
    shutil.copytree(temp_database, db_path, dirs_exist_ok=True, symlinks=True, ignore=copy_ignore)
    return True
  else:
    logging.info(f'\033[93mNot applying changes!\033[0m')
    return False


def CheckTags(data):
  db_path = data['db_path']
  database_decoded = data['db_decoded']
  """Check ID3 tags against Serato database"""
  if re.match('/Volumes', db_path):
    file_base = db_path.split('_Serato_')[0]
  else:
    file_base = '/'
  for i, item in reversed(list(enumerate(database_decoded[1:]))):
    item_filepath = file_base + item[1][1][1]
    item_title = item[1][2][1]
    item_artist = item[1][3][1]
    if os.path.exists(item_filepath):
      id3 = eyed3.load(item_filepath)
      if item_title != id3.tag.title:
        logging.warning(f'{i}/{len(database_decoded) - 1} \033[93mTitle mismatch!\033[0m \033[96mFile:\033[0m {os.path.split(item_filepath)[-1]}\n\t\033[96mDB:\033[0m   {item_title}\n\t\033[96mID3:\033[0m  {id3.tag.title}')
        UpdateTags(id3, data, i)
      elif item_artist != id3.tag.artist:
        logging.warning(f'{i}/{len(database_decoded) - 1} \033[93mArtist mismatch!\033[0m \033[96mFile:\033[0m {os.path.split(item_filepath)[-1]}\n\t\033[96mDB:\033[0m   {item_artist}\n\t\033[96mID3:\033[0m  {id3.tag.artist}')
        UpdateTags(id3, data, i)
      else:
        print(f'{i}/{len(database_decoded) - 1}', end='\r')
    else:
      logging.error(f'{i}/{len(database_decoded) - 1} \033[93mMISSING!\033[0m {item_filepath}')
  print('\033[K')


def UpdateTags(id3, data, i):
  db_path = data['db_path']
  database_decoded = data['db_decoded']
  """Check ID3 tags against Serato database"""
  item = database_decoded[1:][i]
  item_artist = item[1][3][1]
  item_title = item[1][2][1]
  ### WIP: Need to determine the best use case for this and how to do it.
  while True:
    selection = str(input('\nFix Serato [D]B or [I]D3? ').lower())
    if selection == 'd':
      item_artist = id3.tag.artist
      item_title = id3.tag.title
      break
    elif selection == 'i':
      id3.tag.artist = item_artist
      id3.tag.title = item_title
      id3.tag.save()
      break

def Export(data):
  export_filename = f'{data['db_location']}-{datetime.now().strftime("%Y%m%d-%H%M%S")}.txt'
  max_len = max(len(t) for t in data['db_decoded'])  # Find the maximum tuple length
  logging.info(f'\033[96mExporting database in plain text to\033[0m: {export_filename}')
  with open(export_filename, 'w', newline='') as f:
    writer = csv.writer(f)
    for row in data['db_decoded']:
      padded_row = list(row) + [''] * (max_len - len(row))  # Pad with empty strings
      writer.writerow(padded_row)
