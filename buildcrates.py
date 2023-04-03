import configparser
import os
import re
import struct

homedir = os.path.expanduser('~')

config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

# Make new crate from scratch
def buildcrates():
  for root, dirs, files in os.walk(music):
    crate_name = root.replace(music, os.path.basename(music)).replace('/', '%%') + '.crate'
    crate_path = os.path.join(library + '/Subcrates/' + crate_name)
    crate_data = b''
    crate_data += encode([('vrsn', '1.0/Serato ScratchLive Crate')])
    crate_data += encode([('osrt', [('tvcn', '#'), ('brev', '')])])
    crate_data += encode([('ovct', [('tvcn', 'song'), ('tvcw', '0')]), ('ovct', [('tvcn', 'artist'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bpm'), ('tvcw', '0')]), ('ovct', [('tvcn', 'key'), ('tvcw', '0')]), ('ovct', [('tvcn', 'year'), ('tvcw', '0')]), ('ovct', [('tvcn', 'grouping'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bitrate'), ('tvcw', '0')]), ('ovct', [('tvcn', 'undef'), ('tvcw', '0')]), ('ovct', [('tvcn', 'added'), ('tvcw', '0')]), ('ovct', [('tvcn', 'composer'), ('tvcw', '0')]), ('ovct', [('tvcn', 'comment'), ('tvcw', '0')]), ('ovct', [('tvcn', 'location'), ('tvcw', '0')]), ('ovct', [('tvcn', 'filename'), ('tvcw', '0')]), ('ovct', [('tvcn', 'genre'), ('tvcw', '0')]), ('ovct', [('tvcn', 'album'), ('tvcw', '0')]), ('ovct', [('tvcn', 'label'), ('tvcw', '0')])])
    files.sort()
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        file_path = os.path.join(root[1:], file)
        print('Adding {} to crate {}'.format(file_path, crate_name))
        crate_data += encode([('otrk', [('ptrk', file_path)])])
    if len(crate_data) > 0:
      with open(crate_path, 'wb') as crate_file:
        crate_file.write(crate_data)
