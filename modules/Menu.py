import os, sys, logging, time
from modules import Config, Database, Crate, Help, ReplacePath, LocateLostFiles
# import Database
# import Crate
# import Help
# import ReplacePath
# import LocateLostFiles


def Header():
  print(f'\n╔{"═"*66}╗')
  print(f'║{" "*21}Serato Crate Folder Sync{" "*21}║')
  print(f'╚{"═"*66}╝\n')


def Print(data):
  Info(data)
  Options(data)


def Info(data):
  db_path = data['db_path']
  database_music = data['db_music']
  database_music_missing = data['db_music_missing']
  log = data['log']
  logging.info(f'Serato Database: {db_path}\033[K')
  logging.info(f'Configuration File: {data['config_path']}')
  logging.info(f'Log File: {log}')
  print()
  logging.info(f'Database Files: {len(database_music)}')
  logging.info(f'Missing Files:  {len(database_music_missing)}')
  include_parent_crate = Config.Get(data, 'options', 'include_parent_crate', 'False')
  print()
  logging.info(f'Include Parent Folder as Crate: {include_parent_crate}')


def Options(data):
  db_path = data['db_path']
  music_path = data['music_path']
  database_music = data['db_music']
  database_music_missing = data['db_music_missing']
  config = data['config']
  print()
  if db_path and music_path and not len(database_music) > len(database_music_missing):
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
  Action(selection, data)


def OptionsAdvanced(data):
  db_path = data['db_path']
  database_music_missing = data['db_music_missing']
  print('\nB. Backup database')
  backup_path = os.path.join(db_path + 'Backups')
  if os.path.exists(backup_path):
    print('R. Restore database from backup')
  print('X. Rebuild subcrates from scratch')
  print('T. Check ID3 tags against database')
  if len(database_music_missing) > 0:
    print('L. Locate lost files')
  print('U. Update music folder path in database')
  selection = str(input('\nSelect an option: ').lower())
  return selection


def Action(selection, data):
  if selection == 'a':
    selection = OptionsAdvanced(data)
    if selection == 'b':
      Database.Backup(data)
    elif selection == 'r':
      Database.Restore(data)
      sys.exit(0)
    elif selection == 'x':
      Crate.Sync(data, rebuild = True)
      sys.exit(0)
    elif selection == 't':
      Database.CheckTags(data)
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
    Crate.Sync(data)
    sys.exit(0)
  elif selection == 'p':
    Config.ToggleOption(data, 'options', 'include_parent_crate')
  elif selection == 'h':
    Help.Print()
  elif selection == 'q':
    logging.debug(f'Session end')
    sys.exit(0)
  elif selection == 't':
    print('TEST AREA')
    time.sleep(2)
  else:
    time.sleep(1)
