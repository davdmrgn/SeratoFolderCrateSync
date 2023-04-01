def encode(data):
  key_string = data[0]
  value_string = data[1]
  key = key_string.encode('utf-8')
  try:
    if re.match('osrt', key_string):
      # value = []
      # for item in value_string:
      #   for t in item:
      #     value.append(t)
      pass
    else:
      value = value_string.encode('utf-16-be')
      length = struct.pack('>I', len(value))
    return(key + length + value)
  except:
    print('\nERROR: key_string is {}. value_string is {}'.format(key_string, value_string))
##

def encode(data):
  key_string = data[0]
  value_string = data[1]
  key = key_string.encode('utf-8')
  try:
    if re.match('osrt', key_string):
      for v in value_string:
        value = encode(v)
    elif re.match('tvcn|brev', key_string):
      value = value_string
    else:
      value = value_string.encode('utf-16-be')
      length = struct.pack('>I', len(value))
  except:
    print('\nERROR: key_string is {}\n value_string is {}'.format(key_string, value_string))
  return(key + length + value)

##

def encode(data):
  key_string = data[0]
  value_string = data[1]
  key = key_string.encode('utf-8')
  try:
    if re.match('osrt', key_string):
      print('MATCH OSRT')
      osrt_data = []
      for v in value_string:
        print('WE R IN THE V LOOP! key_string is {}. v is {}'.format(key_string, v))
        osrt_data.append(encode(v))
      value = osrt_data
    elif re.match('tvcn|brev', key_string):
      print('MATCH 2ND THING. key_string is {}. value_string is {}'.format(key_string, value_string))
      value = value_string
    else:
      print('WE R IN THE ELSE!')
      value = value_string.encode('utf-16-be')
    length = struct.pack('>I', len(value))
  except:
    print('\nERROR: key_string is {}\n value_string is {}'.format(key_string, value_string))
  return(key + length + value)

##

key_string = test[0]
value_string = test[1]
key = key_string.encode('utf-8')
if re.match('osrt', key_string):
  osrt_data = ''
  for item in value_string:
    for t in item:
      osrt_data += t
      value = osrt_data.encode('utf-8')
else:
  value = value_string.encode('utf-16-be')
length = struct.pack('>I', len(value))
print(key + length + value)

# osrt\x00\x00\x00\x13tvcn\x00\x00\x00\x02\x00#brev\x00\x00\x00\x01\x00
# test[0].encode('utf-8') === b'osrt'
# b = b'osrt\x00\x00\x00\x13tvcn\x00\x00\x00\x02\x00#brev\x00\x00\x00\x01\x00'
# b[i:i+4].decode('utf-8') = 'osrt'
# struct.unpack('>I', b[i+4:i+8])[0] = 19
# b[i+8:i+8+length] = b'tvcn\x00\x00\x00\x02\x00#brev\x00\x00\x00\x01\x00'
# so...
# [ osrt ] [ \x00\x00\x00\x13 ] [ tvcn\x00\x00\x00\x02\x00#brev\x00\x00\x00\x01\x00 ]

##

## This gets the content of the first section of the osrt
a = data[1]
# type(a) = tuple
key = a[0]
# type(a[1]) = list
b = a[1]
# len(b) = 2
c = b[0]
x = b''
d = c[0]
e = d.encode('utf-8') # b'tvcn'
f = c[1].encode('utf-16-be')
g = struct.pack('>I', len(e)) # b'\x00\x00\x00\x02'
x = e + g + f
