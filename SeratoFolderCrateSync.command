import os, argparse, eyed3, time
import Database
import Logger
import Config
import SeratoData
import Music
import Menu
import Select
import Crate


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase verbosity")
  args = parser.parse_args()
  if args.verbose:
    print("Verbose mode enabled")
    eyed3.log.setLevel("DEBUG")
  else:
    eyed3.log.setLevel('ERROR')
  database = Database.Find()
  database_folder = os.path.dirname(database)
  log = Logger.Logger(database_folder)
  config = Config.Read(database_folder)
  database_binary = SeratoData.Read(database)
  database_decoded = SeratoData.Decode(database_binary)
  database_music, database_music_missing = Music.Extract(database_decoded, database_folder)
  if len(database_music) > 0:
    music_folder = Music.Folder(database_music, database_folder)
    while True:
      menu_input = Menu.Print(database_folder, database_music, database_music_missing, log, music_folder, config, database_decoded)
      Menu.Action(menu_input, database_folder, music_folder, config, database_music, database_music_missing, database_decoded)
  else:
    print(f'\033[93mYou have no files in your library\033[0m')
    time.sleep(2)
    print('\033[93mUse the file chooser to select the directory where your music is to build subcrates from scratch\033[0m')
    time.sleep(3)
    music_folder = Select.Directory()
    Crate.Sync(database_folder, rebuild = True)


if __name__ == "__main__":
  if os.name == "posix":
    main()
  else:
    print("macOS only right now")

