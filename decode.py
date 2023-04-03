import configparser
import os
import re
import struct

homedir = os.path.expanduser('~')

config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

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

#decode(data)
