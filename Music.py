import os, re, logging
import Select
import Config


def Extract(self, database_folder):
  database_music = []
  database_music_missing = []
  logging.info(f'Extracting song file locations from database\033[K')
  if re.match('/Volumes', database_folder):
    file_base = database_folder.split('_Serato_')[0]
  else:
    file_base = '/'
  for line in self:
    if line[0] == 'otrk':
      file_path = os.path.join(file_base, line[1][1][1])
      if os.path.exists(file_path):
        print(f'Found {len(database_music) + 1}: {file_path[:Config.TerminalWidth()]}', end='\033[K\r')
        database_music.append(file_path)
      else:
        logging.warning(f'\033[93mMISSING!\033[0m {file_path}\033[K')
        database_music.append(file_path)
        database_music_missing.append(file_path)
  return database_music, database_music_missing


def Folder(self, database_folder):
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
