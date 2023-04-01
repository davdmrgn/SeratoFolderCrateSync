import os
from os.path import basename, splitext, join
import re

library = '/Users/dave/Music/_Serato_'
music = '/Users/dave/Music/Temp'

for root, dirs, files in os.walk(music):
  crate_name = root.replace(music, basename(music)).replace('/', '%%')
  music_path = root
  crate_path = os.path.join(library + '/Subcrates/' + crate_name + '.crate')
  with open(crate_path, 'wb') as crate_file:
    print('Create crate file: ', crate_path)
    crate_file.write('vrsn'.encode('utf-8'))
    crate_file.seek(6)
    crate_file.write('81.0/Serato ScratchLive Crate'.encode('utf-16-be'))
    crate_file.write('osrt'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x19')
    crate_file.write('tvcn'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x08')
    crate_file.write('song'.encode('utf-16-be'))
    crate_file.write('brev'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x01\x00')
    crate_file.write('ovct'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x1a')
    crate_file.write('tvcn'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x08')
    crate_file.write('song'.encode('utf-16-be'))
    crate_file.write('tvcw'.encode('utf-8'))
    crate_file.write(b'\x00\x00\x00\x02\x000')
    files.sort()
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        crate_file.write('otrk'.encode('utf-8'))
        # Changing this for subcrates
        crate_file.write(b'\x00\x00')
        if re.search('%%', crate_name):
          crate_file.write('\x9Aptrk'.encode('utf-8'))
        else:  
          crate_file.write('\x00vptrk'.encode('utf-8'))
        crate_file.write(b'\x00\x00')
        if re.search('%%', crate_name):
          crate_file.write(b'\x00\x92')
        else:
          crate_file.write('\x00n'.encode('utf-8'))
        full_path = os.path.join(root, file)
        print('Adding to crate {}: {}'.format(crate_name.replace('%%', ' || '), full_path))
        binary_full_path = full_path[1:].encode('utf-16-be')
        crate_file.write(binary_full_path)
    crate_file.close()

# https://github.com/Holzhaus/serato-tags
