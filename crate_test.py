import os
import logging
import time
from datetime import datetime
import struct
import re
import configparser
import sys
import shutil
import io


a = '/Volumes/Ten/Google Drive/Serato/_Serato_iMac/Subcrates/Crates 9%%DJ Tools.crate'
with open(a, 'rb') as b:
  data = b.read()

def DecodeBinary(input):
  output = []
  i = 0
  l = 0
  while i < len(input):
    j = i + 4
    key_binary = input[i:j]
    key = key_binary.decode('utf-8')
    k = j + 4
    length_binary = input[j:k]
    length = struct.unpack('>I', length_binary)[0]
    value_binary = input[k:k + length]
    if re.match('^o', key):
      value = DecodeBinary(value_binary)
      l = l + 1
      terminal_width = os.get_terminal_size().columns - 20
      if len(value) != 1:
        print('Decoding {}: {}'.format(l, value[1][1][:terminal_width]), end='\033[K\r')
    elif re.match('(?!^u|^s|^b)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  return(output)

decoded_crate = DecodeBinary(data)
print()
# b'ptrk\x00\x00\x00\xa0\x00U\x00s\x00e\x00r\x00s\x00/\x00d\x00a\x00v\x00e\x00/\x00M\x00u\x00s\x00i\x00c\x00/\x00C\x00r\x00a\x00t\x00e\x00s\x00/\x00C\x00r\x00a\x00t\x00e\x00s\x00 \x009\x00/\x00D\x00J\x00 \x00T\x00o\x00o\x00l\x00s\x00/\x00A\x00l\x00a\x00n\x00 \x00P\x00a\x00r\x00s\x00o\x00n\x00s\x00 \x00P\x00r\x00o\x00j\x00e\x00c\x00t\x00 \x00-\x00 \x00S\x00i\x00r\x00i\x00u\x00s\x00 \x00[\x00P\x00S\x00]\x00.\x00m\x00p\x003'

# def DecodeBinary2(input):
#   output = []
#   i = 0
#   l = 0
#   while i < len(input):
#     j = i + 4
#     key_binary = input[i:j]
#     key = key_binary.decode('utf-8')
#     k = j + 4
#     length_binary = input[j:k]
#     length = struct.unpack('>I', length_binary)[0]
#     value_binary = input[k:k + length]
#     output.append((key, value_binary))
#     i += 8 + length
#   return(output)

# decoded_crate = DecodeBinary2(data)


