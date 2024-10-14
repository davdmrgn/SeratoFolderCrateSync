import os
from modules import Database, Logger, Config, SeratoData, Music
# import Logger
# import Config
# import SeratoData
# import Music


def Build():
  data = {}
  data['db_location'] = Database.Find()
  data['db_path'] = os.path.dirname(data['db_location'])
  data['log'] = Logger.Logger(data)
  data['config'] = Config.Read(data)
  data['db_binary'] = SeratoData.Read(data['db_location'])
  data['db_decoded'] = SeratoData.Decode(data['db_binary'])
  database_music, database_music_missing = Music.Extract(data)
  data['db_music'] = database_music
  data['db_music_missing'] = database_music_missing
  return data
