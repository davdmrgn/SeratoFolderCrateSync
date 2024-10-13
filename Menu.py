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


def Print(database_folder, database_music, database_music_missing, log, music_folder, config, database_decoded):
  Info(database_folder, database_music, database_music_missing, log)
  Options(database_folder, music_folder, database_music, database_music_missing, config, database_decoded)


def Info(database_folder, database_music, database_music_missing, log):
  logging.info(f'Serato Database: {database_folder}\033[K')
  logging.info(f'Configuration File: {Config.File(database_folder)}')
  logging.info(f'Log File: {log}')
  print()
  logging.info(f'Database Files: {len(database_music)}')
  logging.info(f'Missing Files:  {len(database_music_missing)}')
  include_parent_crate = Config.Get(database_folder, 'options', 'include_parent_crate', 'False')
  print()
  logging.info(f'Include Parent Folder as Crate: {include_parent_crate}')


def Options(database_folder, music_folder, database_music, database_music_missing, config, database_decoded):
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
  Action(selection, database_folder, music_folder, config, database_music, database_music_missing, database_decoded)


def OptionsAdvanced(database_folder, database_music_missing):
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


def Action(selection, database_folder, music_folder, config, database_music, database_music_missing, database_decoded):
  if selection == 'a':
    selection = OptionsAdvanced(database_folder, database_music_missing)
    if selection == 'b':
      Database.Backup(database_folder)
    elif selection == 'r':
      Database.Restore(database_folder)
      sys.exit(0)
    elif selection == 'x':
      Crate.Sync(database_folder, music_folder, config, database_music, rebuild = True)
      sys.exit(0)
    elif selection == 't':
      Database.CheckTags(database_folder, database_decoded)
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
    Crate.Sync(database_folder, music_folder, config, database_music)
    sys.exit(0)
  elif selection == 'p':
    Config.ToggleOption(database_folder, config, 'options', 'include_parent_crate')
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
