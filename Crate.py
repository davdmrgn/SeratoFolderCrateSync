import time, logging, os, re
import Database
import Config
import SeratoData


def Sync(database_folder, music_folder, config, database_music, rebuild = False):
  temp_database = Database.Temp.Create(database_folder)
  crate_check, songs_new, songs_mod = Check(temp_database, rebuild, music_folder, config, database_folder, database_music)
  print(f'\033[K')
  if crate_check > 0:
    logging.info(f'  \033[92m+++\033[0m {songs_new} new song{"s" if songs_new > 1 else ""} to add')
    logging.info(f'  \033[93m~~~\033[0m {songs_mod} existing song{"s" if songs_mod > 1 else ""} move into subcrate{"s" if songs_mod > 1 else ""}')
    logging.info(f'      {crate_check} crate{"s" if crate_check > 1 else ""} to update')
    apply = Database.Apply(temp_database, database_folder)
    if apply == True:
      logging.info(f'\033[92mSync done!\033[0m')
  elif crate_check == 0:
    logging.info(f'\r\033[92mNo crate updates required\033[0m\033[K')
  time.sleep(1)
  Database.Temp.Remove(temp_database)


def Check(temp_database, rebuild, music_folder, config, database_folder, database_music):
  crate_updates = 0
  songs_new = 0
  songs_mod = 0
  music_subfolders = []
  for root, dirs, files in os.walk(music_folder):
    include_parent_crate = Config.Get(database_folder, 'options', 'include_parent_crate')
    if include_parent_crate == 'True':
      music_subfolders.append(root)
    else:
      for dir in dirs:
        music_subfolders.append(os.path.join(root, dir))
  music_subfolders.sort()
  for music_subfolder in music_subfolders:
    logging.debug(f'Music subfolder: {music_subfolder}')
    if config.get('options', 'include_parent_crate') == 'True':
      crate_name = music_subfolder.replace(music_folder, os.path.basename(music_subfolder)).replace('/', '%%') + '.crate'
    else:
      crate_name = music_subfolder.replace(music_folder, '')[1:].replace('/', '%%') + '.crate'
    crate_path = os.path.join(temp_database, 'Subcrates', crate_name)
    if os.path.exists(crate_path):
      if rebuild == True:
        logging.info(f'\033[93mRebuilding crate\033[0m: {crate_path}')
        os.remove(crate_path)
        crate_update = Build(crate_path, music_subfolder, database_music)
        crate_updates += crate_update[0]
        songs_new += crate_update[1]
        songs_mod += crate_update[2]
      else:
        logging.debug(f'\033[1F\033[KCrate exists: {crate_path}')
        crate_update = Existing(crate_path, music_subfolder, database_music)
        crate_updates += crate_update[0]
        songs_new += crate_update[1]
        songs_mod += crate_update[2]
    else:
      logging.info(f'Crate does not exist: {crate_path}')
      crate_update = Build(crate_path, music_subfolder)
      crate_updates += crate_update[0]
      songs_new += crate_update[1]
      songs_mod += crate_update[2]
  return crate_updates, songs_new, songs_mod


def Existing(crate_path, music_subfolder, database_music):
  with open(crate_path, 'rb') as f:
    crate_binary = f.read()
  crate_data = SeratoData.Decode(crate_binary)
  crate_length = len(crate_data)
  crate_files = []
  for line in crate_data:
    key = line[0]
    if key == 'otrk':
      crate_files.append(line[1][0][1])
  crate_name = os.path.split(crate_path)[-1]

  songs_new, songs_mod = Scan(database_music, music_subfolder, crate_name, crate_data, crate_path, crate_files)

  if len(crate_data) > crate_length:
    crate_encoded = SeratoData.Encode(crate_data)
    with open(crate_path, 'w+b') as new_crate:
      new_crate.write(crate_encoded)
    return 1, songs_new, songs_mod
  else:
    return 0, songs_new, songs_mod


def Build(crate_path, music_subfolder, database_music):
  crate_name = os.path.split(crate_path)[-1]
  crate_data = []
  crate_data.append(('vrsn', '1.0/Serato ScratchLive Crate'))
  crate_data.append(('osrt', [('tvcn', 'bpm')]))
  crate_data.append(('ovct', [('tvcn', 'song')], ('ovct', [('tvcn', 'artist')]), ('ovct', [('tvcn', 'bpm')]), ('ovct', [('tvcn', 'key')]), ('ovct', [('tvcn', 'year')]), ('ovct', [('tvcn', 'added')])))

  songs_new, songs_mod = Scan(database_music, music_subfolder, crate_name, crate_data, crate_path)

  crate_binary = SeratoData.Encode(crate_data)
  if not os.path.exists(crate_path):
    logging.info(f'\033[96mBuilding new crate file\033[0m: {crate_path}')
    os.makedirs(os.path.dirname(crate_path), exist_ok=True)
  with open(crate_path, 'w+b') as crate_file:
    crate_file.write(crate_binary)
  return 1, songs_new, songs_mod


def Scan(database_music, music_subfolder, crate_name, crate_data, crate_path, crate_files = []):
  songs_new = 0
  songs_mod = 0
  for file in sorted(os.listdir(music_subfolder)):
    if file.endswith(('.mp3', '.ogg', '.alac', '.flac', '.aif', '.wav', '.wl.mp3', '.mp4', '.m4a', '.aac')):
      if re.match('/Volumes', music_subfolder):
        music_root = os.path.split(crate_path)[0]
        file_path = os.path.join(music_subfolder.replace(music_root, '')[1:], file)
        file_full_path = os.path.join(music_root, file_path)
      else:
        file_path = os.path.join(music_subfolder[1:], file)
        file_full_path = '/' + file_path
      if file_path not in crate_files:
        if file_full_path in database_music:
          file_status_color = '\033[93m'
          file_status = f'{file_status_color}~~~\033[0m'
          songs_mod += 1
        else:
          file_status_color = '\033[92m'
          file_status = f'{file_status_color}+++\033[0m'
          songs_new += 1
        crate_name_displayname = crate_name.replace('%%', u' \u2771 ')
        logging.info(f'{file_status} {file_full_path} {file_status_color}\u2771\u2771\u2771\033[0m {crate_name_displayname}')
        crate_data.append(('otrk', [('ptrk', file_path)]))
  return songs_new, songs_mod
