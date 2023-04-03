import configparser
import os
import re
import struct

homedir = os.path.expanduser('~')

config = configparser.ConfigParser()
config.read('config.txt')
library = homedir + config['paths']['library']
music = homedir + config['paths']['music']

crates = []
for root, dirs, files in os.walk(library + '/Subcrates'):
  files.sort()
  for file in files:
    if file.endswith('.crate'):
      crates.append(os.path.join(root, file))

print(crates)

file = crates[-1]

with open(file, 'rb') as f:
  file_contents = f.read()

# decode
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
  
print(result)


def encode(data):
  key = data[0].encode('utf-8')
  value = data[1].encode('utf-16-be')
  length = struct.pack('>I', len(value))
  return(key + length + value)

# encode
i = 0
x = b''
for line in d:
  key = line[0].encode('utf-8')
  if isinstance(line[1], list):
    value = encode(line[1][0])
    length = struct.pack('>I', len(value))
    x += (key + length + value)
  else:
    value = line[1].encode('utf-16-be')
    length = struct.pack('>I', len(value))
    x += (key + length + value)
  i += 1


file = library + '/Subcrates/This better work.crate'
with open(file, 'wb') as crate:
  crate.write(x)
