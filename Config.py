import os, configparser, logging

def File(database_folder):
  config_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}.ini'
  config_path = os.path.join(database_folder, 'Logs', config_filename)
  return config_path

def Read(database_folder):
  config_file = File(database_folder)
  config = configparser.ConfigParser()
  config.read(config_file)
  return config

def Get(database_folder, section, option, default_value = ''):
  config = Read(database_folder)
  if not config.has_option(section, option):
    logging.debug(f'Setting {option} to default value: {default_value}')
    Set(config, section, option, default_value, database_folder)
  return config.get(section, option)

def Set(database_folder, config, section, option, value):
  if not config.has_section(section):
    config.add_section(section)
  config.set(section, option, value)
  config_file = File(database_folder)
  with open(config_file, 'w') as f:
    config.write(f)
  return config

def ToggleOption(database_folder, config, section, option):
  value = Get(database_folder, section, option)
  if value == 'True':
    Set(database_folder, config, section, option, 'False')
  else:
    Set(database_folder, config, section, option, 'True')
  return config
