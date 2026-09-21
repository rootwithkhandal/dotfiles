import os
import shutil
import filecmp

SOURCE_DIR = '/path/to/source'
BACKUP_DIR = '/path/to/backup'

def backup_and_verify():
    try:
        if not os.path.exists(BACKUP_DIR):
            os.makedirs(BACKUP_DIR)
        shutil.copytree(SOURCE_DIR, BACKUP_DIR, dirs_exist_ok=True)
        comparison = filecmp.dircmp(SOURCE_DIR, BACKUP_DIR)
        if comparison.diff_files:
            print("Backup verification failed. Differences found:", comparison.diff_files)
        else:
            print("Backup and verification successful.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    backup_and_verify()