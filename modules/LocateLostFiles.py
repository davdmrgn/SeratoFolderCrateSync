import time, logging, os, eyed3, re
from modules import Database, Select, SeratoData, Config


def Init(data):
  database_music_missing = data['db_music_missing']
  """Entrypoint for missing files"""
  if len(database_music_missing) == 0:
    logging.info('\n\033[92mYou have no missing files in your library\033[0m')
  else:
    print(f'{len(database_music_missing)} missing file(s)')
    temp_database = Database.Temp.Create()
    Updates = Search(temp_database)
    logging.info(f'\033[93m  {Updates} files found\033[0m\033[K')
    time.sleep(1)
    if Updates > 0:
      Database.Apply(data)
    Database.Temp.Remove(temp_database)


def Search(data):
  music_path = data['music_path']
  database_music_missing = data['db_music_missing']
  database_decoded = data['db_decoded']
  """Search for files missing in database"""
  print('\033[93mUse the selector to choose the search folder\033[0m')
  time.sleep(2)
  Updates = 0
  search_path = Select.Directory(music_path)
  for i, item in enumerate(database_music_missing):
    logging.debug(f'{i + 1}/{len(database_music_missing)} Searching for missing song: {item}')
    for ii, db_entry in enumerate(database_decoded[1:]):
      if item[1:] == db_entry[1][1][1]:
        logging.debug(f'{i + 1}/{len(database_music_missing)} Missing song location found in database: [{ii + 1}] {item}')
        Found = Compare(data, ii + 1, search_path)
        if type(Found) is int:
          Updates += Found
        break
  return Updates


def Compare(data, ii, search_path):
  temp_database = data['db_temp']
  database_decoded = data['db_decoded']
  database_music = data['db_music']
  """Compare ID3 tag against database data"""
  db_entry = database_decoded[ii]
  db_entry_filetype = db_entry[1][0][1]
  db_entry_filepath = db_entry[1][1][1]
  db_entry_filename = os.path.split(db_entry_filepath)[-1]
  db_entry_title = db_entry[1][2][1]
  db_entry_artist = db_entry[1][3][1]
  logging.info(f'\033[96mSearching for missing song\033[0m: {db_entry_filepath}')
  for root, dirs, files in os.walk(search_path):
    for file in files:
      if file.endswith(db_entry_filetype):
        file_fullpath = os.path.join(root, file)
        if file_fullpath not in database_music:
          try:
            id3 = eyed3.load(file_fullpath)
            if id3.tag.artist == db_entry_artist and id3.tag.title == db_entry_title:
              print(f'\033[92mID3 tag match\033[0m: {file_fullpath}')
              Update(ii, id3, temp_database)
              return 1
            elif file == db_entry_filename:
              print(f'\033[92mFilename match\033[0m: {file_fullpath}')
              Update(ii, id3, temp_database)
              return 1
          except Exception as e:
            logging.error(f'\nProblem reading ID3 tag: {file_fullpath}')


def Replace(self, logging, find, replace):
  """Replace content in database"""
  output = []
  for i, item in enumerate(self):
    key = item[0]
    if key == 'otrk':
      otrk_data = []
      otrk_item = item[1]
      for item in otrk_item:
        if re.match('pfil|ptrk', item[0]) and find in item[1]:
          p_value = item[1].replace(find, replace)
          logging.info(f'{i - 2}/{len(self) - 3} Replacing: {find[:Config.TerminalWidth()]}\033[K')
          otrk_data.append((item[0], p_value))
        else:
          otrk_data.append(item)
      output.append((key, otrk_data))
    else:
      output.append(item)
  return output


def Update(db_index, id3, temp_database, database_decoded):
  """Update database"""
  old_pfil = database_decoded[db_index][1][1][1]
  database_decoded[db_index][1][1] = ('pfil', id3.path[1:])
  database_decoded[db_index][1][2] = ('tsng', id3.tag.title)
  database_decoded[db_index][1][3] = ('tart', id3.tag.artist)
  database_decoded[db_index][1][25] = ('bovc', b'\x00')
  database_encoded = SeratoData.Encode(database_decoded)
  temp_database_file = os.path.join(temp_database, 'database V2')
  logging.info(f'Updating database: {temp_database_file}')
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
            crate_replaced = Replace(crate_decoded, old_pfil, id3.path[1:])
            crate_replaced_encoded = SeratoData.Encode(crate_replaced)
            logging.info(f'Updating {"Smart" if crate_file.endswith(".scrate") else ""}Crate: ' + crate_fullpath)
            with open(crate_fullpath, 'w+b') as new_data:
              new_data.write(crate_replaced_encoded)
