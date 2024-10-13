import struct, re, io, os

terminal_width = os.get_terminal_size().columns - 20

def Read(self):
  print(f'Reading Serato {"crate" if self.endswith("crate") else "database"} file: {self}', end='\033[K\r')
  with open(self, 'rb') as data:
    binary = data.read()
  return binary

def Decode(self):
  output = []
  i = 0
  while i < len(self):
    a = i + 4
    b = a + 4
    key_binary = self[i:a]
    key = key_binary.decode('utf-8')
    length_binary = self[a:b]
    length = struct.unpack('>I', length_binary)[0]
    value_binary = self[b:b + length]
    if re.match('^o', key):
      value = Decode(value_binary)
      if len(value) > 2:
        value_str = value[1][1]
      elif len(value) == 1:
        value_str = value[0][1]
      else:
        value_str = value
      print(f'Decoding {len(output)}: {value_str[:terminal_width]}', end='\033[K\r')
    elif re.match('(?!^u|^s|^b|^r)' , key):
      value = value_binary.decode('utf-16-be')
    else:
      value = value_binary
    output.append((key, value))
    i += 8 + length
  # print('Decode complete', end='\033[K\r')
  return output

def Encode(self):
  output = io.BytesIO()
  for i, line in enumerate(self):
    key = line[0]
    key_binary = key.encode('utf-8')
    if key == 'vrsn':
      value = line[1]
      value_binary = value.encode('utf-16-be')
    elif re.match('^o', key):
      o_values = line[1]
      if len(o_values) > 2:
        print(f'Encoding {i}: {o_values[1][1][:terminal_width]}', end='\033[K\r')
      elif len(o_values) == 1:
        print(f'Encoding {i}: {o_values[0][1][:terminal_width]}', end='\033[K\r')
      value_binary = b''
      for line in o_values:
        o_key = line[0]
        o_key_binary = o_key.encode('utf-8')
        o_value = line[1]
        if isinstance(o_value, bytes):
          o_value_binary = o_value
        else:
          o_value_binary = o_value.encode('utf-16-be')
        o_length_binary = struct.pack('>I', len(o_value_binary))
        value_binary += (o_key_binary + o_length_binary + o_value_binary)
    length_binary = struct.pack('>I', len(value_binary))
    output.write(key_binary + length_binary + value_binary)
  print('Encode complete', end='\033[K\r')
  return output.getvalue()

def Replace(self, logging, find, replace):
  output = []
  for i, item in enumerate(self):
    key = item[0]
    if key == 'otrk':
      otrk_data = []
      otrk_item = item[1]
      for item in otrk_item:
        if re.match('pfil|ptrk', item[0]) and find in item[1]:
          p_value = item[1].replace(find, replace)
          logging.info(f'{i - 2}/{len(self) - 3} Replacing: {find[:terminal_width]}\033[K')
          otrk_data.append((item[0], p_value))
        else:
          otrk_data.append(item)
      output.append((key, otrk_data))
    else:
      output.append(item)
  return output
