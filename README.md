# Backup scripts for linux

## Install

1. Edit `install.conf` to fit your need

2. Run `install.sh`

## Save

1. Edit `save.conf` to fit your need

2. Run `save.sh` (or wait cron to do it)

## Restore

- WIP

## Configuration

### `install.conf`

- `LOGFILE` : file where logs are recorded

### `save.conf`

- `SERVER` : server name
- `REMOTE_NAME` : remote connection to use to store backup
- `REMOTE_PATH`: path on remote to store backup
- `DAYS_TO_BACKUP` : numbers of days to keep
- `WORKING_DIR` : workspace where temporary files are store
- `BACKUP_DB` : whether or not to backup databases
- `BACKUP_SERVICES` : whether or not to backup services configuration
- `DB_ENGINE_TO_BACKUP` : (optional) database engine to backup
- `SERVICES_TO_BACKUP` : (optional) services to backup
- `FOLDERS_TO_BACKUP` : folders to backup
- `FILES_TO_BACKUP` : files to backup
- `ONLY_SUBFOLDERS` : backup only subfolders of each folders
- `VOLUMES_TO_BACKUP` : docker volumes to backup (set `docker` in `SERVICES_TO_BACKUP`)
- `DATE_FORMAT` : format of the date append at the end of the backup filename (use `FORMAT` option of `date` command)
- `DB_USER` : (optional) default username to use to connect to an database engine
- `DB_PASSWORD` : (optional) default password to use to connect to an database engine
- `{engine}_USER` : (optional) username to use to connect to {engine}
- `{engine}_PASSWORD` : (optional) password to use to connect to {engine}

## Customization

You can add your own script to backup specific database engines or services.

- Save your script in `save.d\engines\` to add custom database engine

- Save your script in `save.d\services\` to add custom service
