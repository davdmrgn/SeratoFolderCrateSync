import os, sys, logging
from datetime import datetime


def Logger(data):
  """Save log file to Serato database"""
  db_path = data['db_path']
  log_filename = f'{os.path.splitext(os.path.basename(sys.argv[0]))[0]}-{datetime.now().strftime("%Y%m%d")}.log'
  log = f'{db_path}/Logs/{log_filename}'
  logging.basicConfig(filename=log, level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', force=True)
  console = logging.StreamHandler()
  console.setLevel(logging.INFO)
  logging.getLogger(None).addHandler(console)
  logging.debug(f'***** Session start *****')
  return log
