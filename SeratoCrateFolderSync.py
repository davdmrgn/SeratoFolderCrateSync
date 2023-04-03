#!/usr/bin/env python3

import configparser
import os
import re
import struct
import time
from datetime import datetime
import logging

# Paths
homedir = os.path.expanduser('~')
config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

# Logging
now = datetime.now()
logfile = '{}/Logs/SeratoCrateFolderSync-{}-{}-{}.log'.format(library, str(now.year), str(now.month), str(now.day))
logging.basicConfig(filename=logfile, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
logging.getLogger('').addHandler(console)
logging.debug('Session start')

def startApp():
  print()
  print('╔══════════════════════════════════════════════════════════════════╗')
  print('║                     Serato Crate Folder Sync                     ║')
  print('╚══════════════════════════════════════════════════════════════════╝')
  print()
  if os.path.exists(library):
    logging.info('\tSerato Database:   ' + library)
  else:
    logging.error('\tSerato Database:   ' + ' - NOT FOUND')
  if os.path.exists(music):
    logging.info('\tMusic Library:   ' + music)
  else:
    logging.error('\tMusic Library:   ' + ' - NOT FOUND')
  if os.path.exists('config.txt'):
    logging.info('\tConfiguration File:   ' + 'config.txt')
  else:
    logging.error('\tConfiguration File:   ' + ' - NOT FOUND')
  if os.path.exists(logfile):
    logging.info('\tLog File:   ' + logfile)
  else:
    logging.error('\tLog File:   ' + ' - NOT FOUND')
  print()
  mainmenu()

def mainmenu():
  print()
  print('S. Synchronize music folders to Serato crates')
  print()
  print('Q. Quit')
  menu = str(input('\nSelect an option: ').lower())
  if menu == 's':
    buildcrates()
  logging.debug('Session end')

# Get a list of all crate files
def getcrates():
  crates = []
  for root, dirs, files in os.walk(library + '/Subcrates'):
    files.sort()
    for file in files:
      if file.endswith('.crate'):
        crates.append(os.path.join(root, file))
  return(crates)

# Convert crate file data into lines of key, value
def decode(data):
  result = []
  i = 0
  while i < len(data):
    try:
      key = data[i:i+4].decode('utf-8')
      length = struct.unpack('>I', data[i+4:i+8])[0]
      binary = data[i+8:i+8 + length]
      if re.match('osrt|ovct|otrk', key):
        value = decode(binary)
        result.append((key, value))
      elif re.match('brev', key):
        if binary == b'\x00':
          value = ''
        else:
          value = decode(binary)
        result.append((key, value))
      else:
        value = binary.decode('utf-16-be')
        result.append((key, value))
      i += 8 + length
    except:
      print('ERROR: i: {}, key: {}, length: {}, binary: {}, value: {}'.format(i, key, length, binary, value))
      break
  return(result)

def encode(data):
  result = b''
  i = 0
  for line in data:
    try:
      key = line[0].encode('utf-8')
      if isinstance(line[1], list):
        sub_list = line[1][0]
        sub_key = sub_list[0].encode('utf-8')
        sub_value = sub_list[1].encode('utf-16-be')
        sub_length = struct.pack('>I', len(sub_value))
        value = (sub_key + sub_length + sub_value)
      else:
        value = line[1].encode('utf-16-be')
      length = struct.pack('>I', len(value))
      result += (key + length + value)
      i += 1
    except:
      #print('ERROR: i: {}, key: {}, length: {}, value: {}'.format(i, key, length, value))
      logging.error('ERROR: i: {}, key: {}, length: {}, value: {}'.format(i, key, length, value))
      break
  return(result)

# Make new crate from scratch
def buildcrates():
  timer(5)
  for root, dirs, files in os.walk(music):
    crate_name = root.replace(music, os.path.basename(music)).replace('/', '%%') + '.crate'
    crate_path = os.path.join(library + '/Subcrates/' + crate_name)
    crate_data = b''
    crate_data += encode([('vrsn', '1.0/Serato ScratchLive Crate')])
    crate_data += encode([('osrt', [('tvcn', 'song'), ('brev', '')])])
    crate_data += encode([('ovct', [('tvcn', 'song'), ('tvcw', '0')]), ('ovct', [('tvcn', 'artist'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bpm'), ('tvcw', '0')]), ('ovct', [('tvcn', 'key'), ('tvcw', '0')]), ('ovct', [('tvcn', 'year'), ('tvcw', '0')]), ('ovct', [('tvcn', 'grouping'), ('tvcw', '0')]), ('ovct', [('tvcn', 'bitrate'), ('tvcw', '0')]), ('ovct', [('tvcn', 'undef'), ('tvcw', '0')]), ('ovct', [('tvcn', 'added'), ('tvcw', '0')]), ('ovct', [('tvcn', 'composer'), ('tvcw', '0')]), ('ovct', [('tvcn', 'comment'), ('tvcw', '0')]), ('ovct', [('tvcn', 'location'), ('tvcw', '0')]), ('ovct', [('tvcn', 'filename'), ('tvcw', '0')]), ('ovct', [('tvcn', 'genre'), ('tvcw', '0')]), ('ovct', [('tvcn', 'album'), ('tvcw', '0')]), ('ovct', [('tvcn', 'label'), ('tvcw', '0')])])
    files.sort()
    for file in files:
      if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
        file_path = os.path.join(root[1:], file)
        #print('Adding {} to crate {}'.format(file_path, crate_name))
        logging.info('Adding {} to crate {}'.format(file_path, crate_name))
        crate_data += encode([('otrk', [('ptrk', file_path)])])
    if len(crate_data) > 0:
      with open(crate_path, 'wb') as crate_file:
        crate_file.write(crate_data)

def timer(sec):
  while sec:
    print('...{}'.format(sec), end='\r')
    time.sleep(1)
    sec -= 1

startApp()
