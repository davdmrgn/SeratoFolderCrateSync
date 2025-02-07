def Print():
  print('\n\033[1mSerato Crate Folder Sync'+ '\033[0m\n\n\tThis tool allows you to take a folder of music and create crates/subcrates in Serato DJ.\n')
  print('\n\033[1mHow does it work?\033[0m\n\n\tThis program will create new or update existing crate files in _Serato_/Subcrates with the music folder\n\tyou choose.\n\n\tYour database V2 file is scanned to find folders where your music is located.\n\n\tNew files are added to _Serato_/Subcrates/*.crate files. These changes are picked up by Serato DJ and added to \n\tyour database by Serato DJ.')
  print('\n\033[1mOptions\033[0m\n')
  print('\tB\tBackup your _Serato_ database to a _Serato_Backups folder. Note: This will not backup any recordings.\n')
  print('\tD\tChange to another _Serato_ database folder (only available when multiple databases found - usually with \n\t\tinternal and external drives).\n')
  print('\tM\tSet the folder where the music is you want to add to Serato.\n')
  print('\tP\tSet parent folder as a parent crate. This is useful for external drives; it keeps the crates on the external \n\t\tseparate from internal crates.\n')
  print('\tX\tRebuild subcrates will overwrite existing crate files with the music found in the selected folders.\n')
  print('\tS\tSynchronize your music folders to Serato crates. It will display the actions it will take a prompt you before \n\t\tapplying changes. Before applying changes, a backup of your existing _Serato_ folder will be taken.\n')
  print('\n\033[1mAdditional Information\033[0m\n')
  print('\tLogs\tLog files are stored in the _Serato_/Logs folder. They contain additional information for troubleshooting.\n')
  input('\n\nPress ENTER to continue')
