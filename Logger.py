import os, logging
from datetime import datetime


def Logger(database):
  """Save log file to Serato database"""
  database_folder = database['folder']
  log_filename = f'{os.path.splitext(os.path.basename(__file__))[0]}-{datetime.now().strftime("%Y-%m-%d")}.log'
  log = f'{database_folder}/Logs/{log_filename}'
  logging.basicConfig(filename=log, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger(None).addHandler(console)
  logging.debug(f'***** Session start *****')
  return log
