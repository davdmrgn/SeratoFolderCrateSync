import os, sys, logging, time
import Config
import Database
import Crate
import Help
import ReplacePath
import LocateLostFiles


def Header():
  print(f'\n╔{"═"*66}╗')
  print(f'║{" "*21}Serato Crate Folder Sync{" "*21}║')
  print(f'╚{"═"*66}╝\n')


def Print(database):
  Info(database)
  Options(database)


def Info(database):
  database_folder = database['folder']
  database_music = database['music']
  database_music_missing = database['missing']
  log = database['log']
  logging.info(f'Serato Database: {database_folder}\033[K')
  logging.info(f'Configuration File: {database['config_path']}')
  logging.info(f'Log File: {log}')
  print()
  logging.info(f'Database Files: {len(database_music)}')
  logging.info(f'Missing Files:  {len(database_music_missing)}')
  include_parent_crate = Config.Get(database, 'options', 'include_parent_crate', 'False')
  print()
  logging.info(f'Include Parent Folder as Crate: {include_parent_crate}')


def Options(database):
  database_folder = database['folder']
  music_folder = database['music_folder']
  database_music = database['music']
  database_music_missing = database['missing']
  config = database['config']
  database_decoded = database['decoded']
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
  Action(selection, database)


def OptionsAdvanced(database):
  database_folder = database['folder']
  database_music_missing = database['missing']
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


def Action(selection, database):
  database_folder = database['folder']
  music_folder = database['music_folder']
  config = database['config']
  database_music = database['music']
  database_music_missing = database['missing']
  database_decoded = database['decoded']
  if selection == 'a':
    selection = OptionsAdvanced(database)
    if selection == 'b':
      Database.Backup(database)
    elif selection == 'r':
      Database.Restore(database)
      sys.exit(0)
    elif selection == 'x':
      Crate.Sync(database, rebuild = True)
      sys.exit(0)
    elif selection == 't':
      Database.CheckTags(database)
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
    Crate.Sync(database)
    sys.exit(0)
  elif selection == 'p':
    Config.ToggleOption(database, 'options', 'include_parent_crate')
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
