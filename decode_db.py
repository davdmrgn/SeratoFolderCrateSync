import configparser
import os
import re
import struct
import time
from datetime import datetime
import logging
import shutil

serato_database = '/Users/dave/Documents/database V2'

with open(serato_database, 'rb') as db:
  db_binary = db.read()

data = db_binary

def decode(input):
  output = []
  i = 0
  while i < len(input):
    key = input[i:i+4].decode('utf-8')
    if re.match('vrsn|ttyp|pfil|tsng|tart|talb|tgen|tlen|tsiz|tbit|tbpm|tcom|ttyr|tad|tkey', key):
      length = struct.unpack('>I', input[i+4:i+8])[0]
      binary = input[i+8:i+8 + length]
      binary_data = binary.decode('utf-16-be')
      print((key, binary_data))
    elif re.match('otrk', key):
      length = struct.unpack('>I', input[i+4:i+8])[0]
      binary = input[i+8:i+8 + length]
      binary_data = decode(binary)
      print(key, (binary_data))
    else:
      length = struct.unpack('>I', input[i+4:i+8])[0]
    # elif key == '':
    #   binary_data = binary
    # else:
    #   length = struct.unpack('>I', input[i+4:i+8])[0]
    #   binary = input[i+8:i+8 + length]
    #   if re.match('bhrt|uadd|ulbl|utme\sbav|bmis|bply|blop|bitu|bovc|bcrt|biro|bwlb|bwll|buns|bbgl|bkrk|bstm', key):
    #     binary_data = binary
    #   # else:
    #   #   binary_data = binary.decode('utf-16-be')
    i += 8 + length

decode(data)
