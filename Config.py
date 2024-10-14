import os, configparser, logging


def TerminalWidth():
  """Trim line endings to prevent weird character wrapping"""
  return os.get_terminal_size().columns - 20


def File(database_folder):
  """Save configuration file inside Serato Logs dir"""
  config_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}.ini'
  config_path = os.path.join(database_folder, 'Logs', config_filename)
  return config_path


def Read(database_folder):
  """Read config file"""
  config_file = File(database_folder)
  config = configparser.ConfigParser()
  config.read(config_file)
  return config


def Get(database_folder, section, option, default_value = ''):
  """Get config value or set a default value if not exist"""
  config = Read(database_folder)
  if not config.has_option(section, option):
    logging.debug(f'Setting {option} to default value: {default_value}')
    Set(config, section, option, default_value, database_folder)
  return config.get(section, option)


def Set(database_folder, config, section, option, value):
  """Set config value and write to file"""
  if not config.has_section(section):
    config.add_section(section)
  config.set(section, option, value)
  config_file = File(database_folder)
  with open(config_file, 'w') as f:
    config.write(f)
  return config


def ToggleOption(database_folder, config, section, option):
  """Toggle boolean value"""
  value = Get(database_folder, section, option)
  if value == 'True':
    Set(database_folder, config, section, option, 'False')
  else:
    Set(database_folder, config, section, option, 'True')
  return config
