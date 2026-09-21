import os
import shutil
import time

TEMP_DIR = '/tmp'
AGE_THRESHOLD = 7 * 24 * 60 * 60  # 7 days in seconds

def clean_temp_files():
    now = time.time()
    for filename in os.listdir(TEMP_DIR):
        file_path = os.path.join(TEMP_DIR, filename)
        if os.stat(file_path).st_mtime < now - AGE_THRESHOLD:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.remove(file_path)
                print(f'Removed file: {file_path}')
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
                print(f'Removed directory: {file_path}')

if __name__ == "__main__":
    clean_temp_files()