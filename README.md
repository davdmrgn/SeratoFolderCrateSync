# SeratoFolderCrateSync

Syncrhonize music folders to Serato crates

> I wrote this for me. YMMV

## What does it do?

- Have all your music in a folder with subfolders? This sets your subfolders to subcrates.
- Back up and restore your database (automatic backups when making changes).
- _Relocate lost files_ like in Serato DJ.
- Moved all your files from one directory to another? Relocate lost files taking too long? Find and replace against your database.

## Requirements

- macOS (not tested on Windows)
- Python 3
  > Python can be installed via Xcode Command Line Tools: `xcode-select --install`

## Usage

- Open Terminal
- Option 1:
  ```
  python3 SeratoCrateFolderSync.command
  ```
- Option 2:
  ```
  chmod +x SeratoCrateFolderSync.command
  ./SeratoCrateFolderSync.command
  ```
  > Note: Option 2 may allow you to double-click the file from Finder to run.

## Limitations

- Custom crate columns not yet supported
- Will not delete crates (recommend deleting crates manually in Serato)

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
