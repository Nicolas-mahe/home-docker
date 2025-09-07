# applicationBackup.sh
This script is for backing up docker application where a copy isn't enough.

## Usage
the script will looking for *file.conf* in same folder or in all subfolder

## Vars List

| Vars Name        | Default Value | Description                                                                    |
|------------------|---------------|--------------------------------------------------------------------------------|
| AppName          |               | Name of the application                                                        |
| Cpattern         | exact         | Container pattern use to identify it can be exact,startswith,endswith,contains |
| CommandToRun     |               | Command to run in the container with shell                                     |
| BackupFolderName |               | Name of the folder where to place the backup                                   |
| BackupPrefix     |               | Prefix for create/delete backups files                                         |
| BackupSuffix     |               | Suffix for create/delete backups files                                         |
| BackupRetention  | 1             | Number of backups (matching with Prefix and/or suffix) to keep                 |

### Specificities
- For *CommandToRun*, you can use other vars presente in the list with:
    | Vars Name        | Valus to use in command |
    |------------------|-------------------------|
    | AppName          | __APP_NAME__            |
    | BackupFolderName | __BACKUP_FOLDER_NAME__  |
    | BackupPrefix     | __PREFIX_NAME__         |
    | BackupSuffix     | __SUFFIX_NAME__         |

- For *CommandToRun*, It's possible to use some environment vars for the container:
    | Env Vars Name        | Description | Value to use in command |
    |----------------------|-------------|-------------------------|
    | POSTGRES_USER        | User name   | __POSTGRES_USER__       |