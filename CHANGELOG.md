# Change Log

## [0.04](https://github.com/davdmrgn/SeratoFolderCrateSync/releases/tag/v0.04) - 2023-04-20

### Added
- Support for multiple Serato databases (including external drives)
- Search all drives for `_Serato_` folder(s) at launch
- Search `database V2` file for music location at launch

### Changed
- Config file name and location (now stored in Serato Logs directory to support different settings for different databases/drives)
- Clear screen on start

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