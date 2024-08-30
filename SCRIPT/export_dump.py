import os
import re
from datetime import datetime
from collections import defaultdict
import subprocess
import logging

# Remote machine details
remote_user = "xxx"
remote_host = "xxx"
remote_directory = "xxx"
ssh_key_path = "xxx"  # Path to your SSH private key

# Local directory path where files will be copied
local_directory = "xxx"

# Logging configuration
log_file_path = os.path.join(local_directory, "backups_dumps.logs")

# Logger configuration
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# File handler for logging
file_handler = logging.FileHandler(log_file_path)
file_handler.setLevel(logging.INFO)

# Stream handler for standard output
stream_handler = logging.StreamHandler()
stream_handler.setLevel(logging.INFO)

# Log format
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
stream_handler.setFormatter(formatter)

# Add handlers to the logger
logger.addHandler(file_handler)
logger.addHandler(stream_handler)

# Function to extract key, date and time, and extension from filename
def extract_info_from_filename(filename):
    pattern = r"vzdump-[a-z]+-(\d+)-(\d{4}_\d{2}_\d{2}-\d{2}_\d{2}_\d{2})\.(.+)"
    match = re.search(pattern, filename)
    if match:
        key = match.group(1)
        date_str = match.group(2)
        extension = match.group(3)
        date_time = datetime.strptime(date_str, "%Y_%m_%d-%H_%M_%S")
        return key, date_time, extension
    return None, None, None

# Function to get the list of remote files
def get_remote_files():
    ssh_command = [
        "ssh",
        "-i", ssh_key_path,
        f"{remote_user}@{remote_host}",
        f"ls {remote_directory}"
    ]
    try:
        result = subprocess.run(ssh_command, capture_output=True, text=True, check=True)
        remote_files = result.stdout.splitlines()
        return remote_files
    except subprocess.CalledProcessError as e:
        logger.error(f"Error retrieving remote files: {e}")
        return []

# Function to get the list of local files
def get_local_files(local_directory):
    try:
        local_files = os.listdir(local_directory)
        return local_files
    except OSError as e:
        logger.error(f"Error retrieving local files: {e}")
        return []

# Retrieve remote and local files
remote_files = get_remote_files()
local_files = get_local_files(local_directory)

# Group files by key, extension, and date/time
file_dict = defaultdict(lambda: defaultdict(list))

# Fill dictionary with remote files
for file in remote_files:
    key, date_time, extension = extract_info_from_filename(file)
    if key and date_time and extension:
        file_dict[key][extension].append((date_time, file))

# Find the most recent file for each key and extension
latest_files = defaultdict(dict)

for key, ext_dict in file_dict.items():
    for ext, files in ext_dict.items():
        latest_file = max(files, key=lambda x: x[0])[1]
        latest_files[key][ext] = latest_file

# Delete local files that are not on the remote server, except for the log file
remote_files_set = set(remote_files)
for local_file in local_files:
    if local_file not in remote_files_set and local_file != os.path.basename(log_file_path):
        local_path = os.path.join(local_directory, local_file)
        try:
            os.remove(local_path)
            logger.info(f"Deleted file: {local_path}")
        except OSError as e:
            logger.error(f"Error deleting file {local_path}: {e}")

# Sort keys in ascending order
sorted_keys = sorted(latest_files.keys(), key=int)

# Generate and execute SCP commands for files not present locally
for key in sorted_keys:
    for ext, file in latest_files[key].items():
        local_path = os.path.join(local_directory, file)
        if file not in local_files:
            remote_path = f"{remote_directory}/{file}"
            scp_command = [
                "scp",
                "-i", ssh_key_path,
                f"{remote_user}@{remote_host}:{remote_path}",
                local_path
            ]
            try:
                logger.info(f"Copying file {remote_path} to {local_path}...")
                subprocess.run(scp_command, check=True)
                logger.info(f"Copy successful: {local_path}")
            except subprocess.CalledProcessError as e:
                logger.error(f"Error copying file {file}: {e}")
        else:
            logger.info(f"Copy skipped: {file} already exists locally.")

logger.info("Operations completed.")