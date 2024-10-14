import os, configparser, logging
import Database
import Logger
import Config
import SeratoData
import Music


def TerminalWidth():
  """Trim line endings to prevent weird character wrapping"""
  return os.get_terminal_size().columns - 20


def Dict():
  database = {}
  database.update({'location': Database.Find()})
  database.update({'folder': os.path.dirname(database['location'])})
  database.update({'log': Logger.Logger(database)})
  database.update({'config': Config.Read(database)})
  database.update({'binary': SeratoData.Read(database['location'])})
  database.update({'decoded': SeratoData.Decode(database['binary'])})
  Music.Extract(database)
  return database


def File(database):
  """Save configuration file inside Serato Logs dir"""
  config_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}.ini'
  config_path = os.path.join(database['folder'], 'Logs', config_filename)
  database.update({'config_path': config_path})
  return database


def Read(database):
  """Read config file"""
  File(database)
  config_file = database['config_path']
  config = configparser.ConfigParser()
  config.read(config_file)
  database.update({'config': config})
  return database['config']


def Get(database, section, option, default_value = ''):
  """Get config value or set a default value if not exist"""
  database_folder = database['folder']
  config = Read(database)
  if not config.has_option(section, option):
    logging.debug(f'Setting {option} to default value: {default_value}')
    Set(config, section, option, default_value, database_folder)
  return config.get(section, option)


def Set(database, section, option, value):
  """Set config value and write to file"""
  config = database['config']
  if not config.has_section(section):
    config.add_section(section)
  config.set(section, option, value)
  File(database)
  config_file = database['config_path']
  with open(config_file, 'w') as f:
    config.write(f)
  return config


def ToggleOption(database, section, option):
  """Toggle boolean value"""
  database_folder = database['folder']
  config = database['config']
  value = Get(database, section, option)
  if value == 'True':
    Set(database, section, option, 'False')
  else:
    Set(database, section, option, 'True')
  return config
