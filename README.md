# SeratoFolderCrateSync

Syncrhonize music folders to Serato crates

- Version: 0.05
- macOS only (not tested on Windows)

> I wrote this for my specific use case, with the ability to adapt to other configurations later.

## Requirements

- Python3
  > Python can be installed via Xcode Command Line Tools: `xcode-select --install`

## Usage


- Open Terminal
- Make file executable
  ```
  chmod +x ./SeratoCrateFolderSync.command
  ```
- Run the app
  - Right-click [SeratoCrateFolderSync.command](SeratoCrateFolderSync.command) > Open
    - Accept any security warnings
  - or, in Terminal
    ```
    ./SeratoCrateFolderSync.command
    ```

## How does it work?

- Script will:
  - Search for `_Serato_` database directories
  - Scan songs in `database V2` file to find song locations
  - Scan folders and create/update crates matching your folder structure
  - Only apply changes to crate files with your confirmation
- You may toggle the option to include the parent folder as a parent crate
- New crates will be created; existing crates will add new songs
- If any updates, existing crates will be backed up to `_Serato_Backups`
- Backups will not contain files in `Recording*` directories to save disk space
- This script updates files in `/Subcrates` directory on Sync; does not modify:
  - Smart crates
- Can bulk find/replace path of files in `database V2` when moving library
- Script preferences are saved to a `ini` file in `_Serato_/Logs`
- Script saves logs in `_Serato_/Logs`

## Limitations

- Not supported on Windows
- Custom crate columns not yet supported
- Will not delete crates (recommend deleting crates manually in Serato)
- Not all functions are fully tested

<details><summary>More info</summary><p>

## Parent Crate Option

- Include the top level folder as a crate? True
  ```
  Example of True:
    Crates
    ├─ Top 40
    ├─ Chill
    ├─ R&B
    └─ House
  ```
- Do not include the top level folder as a crate? False
  ```
  Example of False:
    Top 40
    Chill
    R&B
    House
  ```
## Crate File Info

In each frame/tag/code/etc, bytes...

- 0:3 have a Serato tag (legend below)
- 4:7 is the length of the data
- 8:8+length is the remainder of the data
- 0:4 can be decoded as utf-8
- 8:8+length can be decoded as utf-16-be (big endian)

## Fields

Source: https://github.com/Holzhaus/serato-tags/blob/master/scripts/database_v2.py

- Database
  - `vrsn`: Version
  - `otrk`: Track
  - `ttyp`: File Type
  - `pfil`: File Path
  - `tsng`: Song Title
  - `tlen`: Length
  - `tbit`: Bitrate
  - `tsmp`: Sample Rate
  - `tbpm`: BPM
  - `tadd`: Date added
  - `uadd`: Date added
  - `tkey`: Key
  - `bbgl`: Beatgrid Locked
  - `tart`: Artist
  - `utme`: File Time
  - `bmis`: Missing
- Crates
  - `osrt`: Sorting
  - `brev`: Reverse Order
  - `ovct`: Column Title
  - `tvcn`: Column Name
  - `tvcw`: Column Width
  - `ptrk`: Track Path

</p></details>
