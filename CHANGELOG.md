# Change Log

## 0.066
- Change .py to .command

## 0.065
- Add export database as plain text
- Fix new crate build
- Move code to modules
- Miscellaneous fixes


## 0.064
- Massive reorganization of code (functions, modules, variables, etc.)
- Fix file chooser

## 0.063 - 2024-09-25
- Add song counts
- Update outputs
- Relocate: Don't apply if no files found
- No crates? No files? No database? No problem.

## [0.061](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.061) - 2024-02-21
- Relocate lost files added
- Check/Compare ID3 tags of files against database
- Set a default value for include parent crate if config file does not exist

## [0.052](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.052) - 2024-01-03
- Moved code around and changed some logic
- Add find/replace support for SmartCrates
- Rename settings file to match project
- Format methods changed to f-strings
- Fix database selection
- Add output for existing files in database

## [0.051](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.051) - 2024-01-03
- Fix music paths search and selection

## [0.05](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.05) - 2024-01-01
- Major code changes to support database V2 interactions
- Can find/replace against database; useful (faster) when you move your library and don't want to use Relocate Lost Files in Serato

## [0.043](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.043) - 2023-05-08

### Fixed
- Music path selector

## [0.042](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.042) - 2023-04-24

### Fixed
- Temp database remove error on sync
- Properly logging when a moved file already exists in database

### Changed
- Debug logging now shows music folder and crate file path

## [0.041](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.041) - 2023-04-22

### Added
- Folder chooser dialog to add a new folder to sync

### Changed
- Remove dependency on psutil to find libraries on all drives
- Logic used to determine where music files are at start

## [0.04](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.04) - 2023-04-20

### Added
- Help
- Backup only option
- Restore from backup option
- External drive support
- Support for multiple Serato databases
- Search all drives for `_Serato_` folder(s) at launch and menu reload
- Ability to change `_Serato_` database without leaving application
- Search `database V2` file for music location at launch
- Show if an added file already exists in database V2 or not

### Fixed
- Change music location

### Changed
- Config file name and location (now stored in Serato Logs directory to support different settings for different databases/drives)
- Clear screen on start
- Consolidate logging to daily
- Prompt before making changes; remove test mode
- Parent crate toggle display
- Function uses TitleCase to differentiate from built-in functions
- Remove change database location option
- No/Invalid entry for change music location reverts to default

## [0.03](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.03) - 2023-04-14

### Added
- Change music and library menu items functional

### Fixed
- Running multiple tests brings you back to the menu and resets the update count
- Test mode display

## [0.021](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.021) - 2023-04-12

### Added
- Incremental synchronizing
- Log files show more detail than stdout with debug logging
- Write to temp folder first, then move folders/files around as needed
- Optional rebuild all crates, if existing
- Test mode (run without applying changes)

### Fixed

## [0.01](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.01) - 2023-04-05

### Added
- Exclude some files and folders from backups
- Code comments
- Parent crate option: Synchronize top-level crate or child crates
- File and folder counts
- Don't show sync command if there are no files/folders to synchronize

### Changed
- Version numbering and Git branch names
- Log and stdout output

### Fixed
- Config file format [.ini]
- Update config file options from menu

## [0.00] - 2023-04-03

- Initial release
