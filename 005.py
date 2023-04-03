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

file = crates[-1]

with open(file, 'rb') as f:
  file_contents = f.read()

d = decode(file_contents)

# decoded file is now in d. you get a list if you hit it with a for loop.

# first, we encode existing data, then we do it from scratch

def encode(data):
  i = 0
  for line in data:
    x = ''
    key_source = line[0].encode('utf-8')
    if isinstance(line[1], list):
      print('i: {}\t{}\t{}'.format(i, key_source, line[1]))
    else:
      value_source = line[1].encode('utf-16-be')
      length = struct.pack('>I', len(value_source))
      print('i: {}\t{}'.format(i, key_source + length + value_source))
    i += 1


encode(data)



    value_source = line[1]
    if type(value_source) == 'list':
      y = encode(line[1])
      x += y
    return(x)

  print('key_source: {}\tvalue_type: {}\tvalue_source: {}'.format(key_source, value_type, value_source))
  i += 1





  if type(line[1]) == 'bytes':
    value = line[1].encode('utf-16-be')
    print ('i: {}, key: {}, value: {}'.format(i, key, value))
  else:
    if re.match('osrt|ovct|otrk', key):
      print(line[1])
    else:
      print(line[1])
  i += 1



osrt\x00\x00\x00\x1btvcn\x00\x00\x00\n\x00a\x00l\x00b\x00u\x00mbrev\x00\x00\x00\x01\x00ovct\x00\x00\x00\x1atvcn\x00\x00\x00\x08\x00s\x00o\x00n\x00gtvcw\x00\x00\x00\x02\x000ovct\x00\x00\x00\x1etvcn\x00\x00\x00\
osrt\x00\x00\x00\x12tvcn\x00\x00\x00\n\x00a\x00l\x00b\x00u\x00m