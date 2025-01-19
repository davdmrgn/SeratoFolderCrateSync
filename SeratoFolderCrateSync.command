#!/usr/bin/env python3

import os, argparse, eyed3, time
from modules import Config, Music, Menu, Select, Crate


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase verbosity")
  args = parser.parse_args()
  if args.verbose:
    print("Verbose mode enabled")
    eyed3.log.setLevel("DEBUG")
  else:
    eyed3.log.setLevel('ERROR')
  data = Config.Data()
  if len(data['db_music']) > 0:
    Music.Folder(data)
    while True:
      menu_input = Menu.Print(data)
      Menu.Action(menu_input, data)
  else:
    print(f'\033[93mYou have no files in your library\033[0m')
    time.sleep(2)
    print('\033[93mUse the file chooser to select the directory where your music is to build subcrates from scratch\033[0m')
    time.sleep(3)
    data['music_path'] = Select.Directory()
    Crate.Sync(data, rebuild = True)


if __name__ == "__main__":
  if os.name == "posix":
    main()
  else:
    print("macOS only right now")

