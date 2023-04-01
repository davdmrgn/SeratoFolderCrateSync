import os
from os.path import basename, splitext, join
import re
import struct

library = '/Users/dave/Music/_Serato_'
music = '/Users/dave/Music/Crates'

file = library + '/Subcrates/Temp.crate'

with open(file, 'rb') as f:
  file_contents = f.read()

def decode(data):
  result = []
  i = 0
  while i < len(data):
    key = data[i:i+4].decode('utf-8')
    length = struct.unpack('>I', data[i+4:i+8])[0]  # 56
    binary = data[i+8:i+8+length]
    try:
      if re.match('osrt', key):
        value = decode(binary)
      elif key == 'brev':
        pass
      else:
        value = binary.decode('utf-16-be')
    except:
      print('\nERROR: i is {}\nkey is {}\nbinary is {}\n\n'.format(i, key, binary))
    result.append((key, value))
    i += 8 + length
  return(result)

data = decode(file_contents)
