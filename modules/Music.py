import os, re, logging
from modules import Select, Config


def Extract(data):
  db_path = data['db_path']
  """Extract song file locations from database"""
  database_music = []
  database_music_missing = []
  logging.info(f'Extracting song file locations from database\033[K')
  if re.match('/Volumes', db_path):
    file_base = db_path.split('_Serato_')[0]
  else:
    file_base = '/'
  for line in data['db_decoded']:
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


def Folder(data):
  db_path = data['db_path']
  """Get all folders from files in database"""
  print('Finding music folder from files in database\033[K')
  file_paths = set()
  for file in data['db_music']:
    """Exclude recordings in _Serato_ folder"""
    if db_path not in file:
      print(os.path.dirname(file), end='\033[K\r')
      file_paths.add(os.path.dirname(file))
  print('\033[K')
  file_paths = sorted(file_paths)
  commonpath = os.path.commonpath(file_paths)
  if commonpath in file_paths and len(re.findall(commonpath, str(file_paths))) == len(file_paths):
    logging.info(f'Music location: {commonpath}')
    data['music_path'] = commonpath
    return data
  else:
    """Search the parent of all folders and match to previous list"""
    folder_names = {}
    for path in file_paths:
      for root, dirs, files in os.walk(os.path.dirname(path)):
        if len(dirs) > 1 and re.findall(root, str(file_paths)):
          logging.debug(f'Found music directory {root} with {len(dirs)} subdirectories')
          folder_names.update({root: len(dirs)})
  
    """Sort the counts"""
    folder_names = dict(sorted(folder_names.items(), key=lambda item: item[1], reverse=True))
    logging.debug(f'Found paths: {folder_names}')

    folder_check = []
    for found_path in folder_names:
      folder_check.append(found_path)

    if folder_check[0] == os.path.commonpath(folder_check):
      logging.debug(f'Music location found: {folder_check[0]}')
      data['music_path'] = list(folder_names)[0]
      return data
    else:
      data['music_path'] = Select.Item(folder_names)
      return data
