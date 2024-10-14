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
  database = Config.Dict()
  if len(database['music']) > 0:
    Music.Folder(database)
    # database.update({'music_folder': music_folder})
    while True:
      menu_input = Menu.Print(database)
      Menu.Action(menu_input, database)
  else:
    print(f'\033[93mYou have no files in your library\033[0m')
    time.sleep(2)
    print('\033[93mUse the file chooser to select the directory where your music is to build subcrates from scratch\033[0m')
    time.sleep(3)
    database.update({'music_folder': Select.Directory()})
    Crate.Sync(database, rebuild = True)


if __name__ == "__main__":
  if os.name == "posix":
    main()
  else:
    print("macOS only right now")

