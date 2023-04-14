# SeratoFolderCrateSync

Syncrhonize music folders to Serato crates

- Version: 0.03

## Requirements

- Python3
  > Python can be installed via Xcode Command Line Tools: `xcode-select --install`

## Usage

- I wrote this for my specific use case, with the ability to adapt to other configurations later
- macOS
- Set Serato library and music paths in [`config.ini`](config.ini)
- Double click [him](SeratoCrateFolderSync.command)

## Limitations

- Not tested with external drives/libraries
- Custom crate columns not yet supported
- Will not delete crates (recommend deleting crates manually in Serato)

<details><summary>More info</summary><p>

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
