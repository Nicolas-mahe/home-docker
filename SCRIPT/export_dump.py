import os
import re
from datetime import datetime
from collections import defaultdict
import subprocess
import logging
from logging.handlers import RotatingFileHandler
import json

# Function to set logging with date-based filenames and rotation
def setup_logging(log_directory, max_log_files=10, max_log_size=10*1024*1024):
    log_directory = os.path.join(log_directory, 'LOGS')
    
    # Ensure the log directory exists
    if not os.path.exists(log_directory):
        os.makedirs(log_directory)
    
    # Create a log filename with the current date and time
    log_filename = datetime.now().strftime("backups_dumps_%Y-%m-%d_%H-%M-%S.logs")
    log_file_path = os.path.join(log_directory, log_filename)
    
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    # Set the logging rotation
    file_handler = RotatingFileHandler(
        log_file_path,
        maxBytes=max_log_size,
        backupCount=max_log_files - 1  # Keep the most recent `max_log_files` logs
    )
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
    
    # Clean up old log files
    cleanup_old_logs(log_directory, max_log_files, logger)
    
    return logger, log_file_path

# Function to clean up old log files, keeping only the latest `max_log_files` files
def cleanup_old_logs(log_directory, max_log_files, logger):
    all_logs = sorted(
        [os.path.join(log_directory, f) for f in os.listdir(log_directory) if f.endswith('.logs')],
        key=os.path.getmtime
    )
    while len(all_logs) > max_log_files:
        oldest_log = all_logs.pop(0)
        os.remove(oldest_log)
        logger.info(f"Deleted old log file: {oldest_log}")

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
def get_remote_files(remote_user, remote_host, remote_directory, ssh_key_path):
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

# Function to load configuration from a JSON file
def load_config(config_file):
    with open(config_file, 'r') as file:
        config = json.load(file)
    return config

# Function to delete local files not in the recent files list
def delete_files_not_in_recent_list(local_files, recent_files, local_directory, logger):
    recent_files_set = set(recent_files)
    for local_file in local_files:
        local_path = os.path.join(local_directory, local_file)
        
        # Check if it's a file and not a directory
        if os.path.isfile(local_path):
            if local_file not in recent_files_set and not local_file.endswith('.logs'):
                try:
                    os.remove(local_path)
                    logger.info(f"Deleted file: {local_path}")
                except OSError as e:
                    logger.error(f"Error deleting file {local_path}: {e}")
            else:
                logger.info(f"Keeping file: {local_file} (in recent files list)")
        else:
            logger.info(f"Skipping directory: {local_path}")

# Load configuration
config_file = os.path.expanduser('~/home-docker/SCRIPT/secret.json')  # Path to the configuration file
config = load_config(config_file)

# Extract variables from configuration
remote_user = config.get('remote_user')
remote_host = config.get('remote_host')
remote_directory = config.get('remote_directory')
ssh_key_path = config.get('ssh_key_path')
local_directory = config.get('local_directory')
log_directory = config.get('log_directory', local_directory)  # Default to local_directory if not specified

if not all([remote_user, remote_host, remote_directory, ssh_key_path, local_directory]):
    raise ValueError("One or more configuration values are missing. Please check your config file.")

# Setup logging
logger, log_file_path = setup_logging(log_directory)

# Retrieve remote and local files
remote_files = get_remote_files(remote_user, remote_host, remote_directory, ssh_key_path)
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

# Load the list of recent files (could be remote files, or another custom list)
# Example: This could be the `latest_files` dictionary you've already built
recent_files = []
for key, ext_dict in latest_files.items():
    for ext, file in ext_dict.items():
        recent_files.append(file)

# Call the updated delete function
delete_files_not_in_recent_list(local_files, recent_files, local_directory, logger)

logger.info("File cleanup completed.\n")


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
                logger.debug(f"Copying file {remote_path} to {local_path}...")
                subprocess.run(scp_command, check=True)
                logger.info(f"Copy successful: {local_path}")
            except subprocess.CalledProcessError as e:
                logger.error(f"Error copying file {file}: {e}")
        else:
            logger.info(f"Copy skipped: {file} already exists locally.")

logger.info("Operations completed.")
