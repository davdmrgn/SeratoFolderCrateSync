import logging, time, os, re
from modules import Database, SeratoData, LocateLostFiles


def Find(music_path):
  """Find folder path for music"""
  logging.info(f'\n\n Music folder is: {music_path}')
  while True:
    find = str(input('\n Enter the portion of the path to replace: '))
    if len(find) > 1 and re.search(find, music_path):
      replace = str(input(' Enter the new replacement portion: '))
      Replace(find, replace)
    else:
      logging.warning('Nope')
      time.sleep(1)
    break


def Replace(find, replace, database_decoded):
  """Find and replace folder path for music"""
  temp_database = Database.Temp.Create()
  """Database"""
  database_replaced = LocateLostFiles.Replace(database_decoded, find, replace)
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
        crate_replaced = LocateLostFiles.Replace(crate_decoded, find, replace)
        crate_replaced_encoded = SeratoData.Encode(crate_replaced)
        logging.debug('Updating Crate: ' + crate_fullpath)
        with open(crate_fullpath, 'w+b') as new_data:
          new_data.write(crate_replaced_encoded)
  Database.Apply(temp_database)
  Database.Temp.Remove(temp_database)
