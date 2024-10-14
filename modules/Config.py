import os, sys, configparser, logging


def TerminalWidth():
  """Trim line endings to prevent weird character wrapping"""
  return os.get_terminal_size().columns - 20


def File(data):
  """Save configuration file inside Serato Logs dir"""
  config_filename = f'{os.path.splitext(os.path.basename(sys.argv[0]))[0]}.ini'
  config_path = os.path.join(data['db_path'], 'Logs', config_filename)
  data['config_path'] = config_path
  return data


def Read(data):
  """Read config file"""
  File(data)
  config_file = data['config_path']
  config = configparser.ConfigParser()
  config.read(config_file)
  data['config'] = config
  return data['config']


def Get(data, section, option, default_value = ''):
  """Get config value or set a default value if not exist"""
  db_path = data['db_path']
  config = Read(data)
  if not config.has_option(section, option):
    logging.debug(f'Setting {option} to default value: {default_value}')
    Set(config, section, option, default_value, db_path)
  return config.get(section, option)


def Set(data, section, option, value):
  """Set config value and write to file"""
  config = data['config']
  if not config.has_section(section):
    config.add_section(section)
  config.set(section, option, value)
  File(data)
  config_file = data['config_path']
  with open(config_file, 'w') as f:
    config.write(f)
  return config


def ToggleOption(data, section, option):
  """Toggle boolean value"""
  config = data['config']
  value = Get(data, section, option)
  if value == 'True':
    Set(data, section, option, 'False')
  else:
    Set(data, section, option, 'True')
  return config
