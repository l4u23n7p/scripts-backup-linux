#!/bin/bash

# set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${ROOT}/$(basename "${BASH_SOURCE[0]}")"
BASE="$(basename ${FILE}.sh)"
LOGDATE="date -Iseconds"

echo "[$($LOGDATE)] Import config"

source ${ROOT}/save.conf

curday=$(date +${DATE_FORMAT})

##################################
# Create local working directory and collect all data
##################################

echo "[$($LOGDATE)] Create working directory: ${WORKING_DIR}"

rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}
cd ${WORKING_DIR}

##################################
# Backup Database
##################################

if [ "${BACKUP_DB}" = "true" ]
then
    echo "[$($LOGDATE)] Backup DB"
    mkdir ${WORKING_DIR}/databases
    for engine in ${DB_ENGINE_TO_BACKUP[*]}
    do
        if test -f "${ROOT}/save.d/engines/${engine}.sh"
        then
            mkdir ${WORKING_DIR}/databases/${engine}
            source "${ROOT}/save.d/engines/${engine}.sh"
        else
            echo "[$($LOGDATE)] ${engine} is not supported"
        fi
    done
    echo "[$($LOGDATE)] Databases saved succesfully"
fi


##################################
# Backup Service configuration
##################################

if [ "${BACKUP_SERVICES}" = "true" ]
then
    echo "[$($LOGDATE)] Backup services"
    mkdir ${WORKING_DIR}/services
    for service in ${SERVICES_TO_BACKUP[*]}
    do
        echo "[$($LOGDATE)] processing ${service}"
        if test -f "${ROOT}/save.d/services/${service}.sh"
        then
            source "${ROOT}/save.d/services/${service}.sh"
        else
            if test -d "/etc/${service}"
            then
                cd /etc
                tar czf ${WORKING_DIR}/services/${service}.tar.gz ./${service}
            else
                echo "[$($LOGDATE)] ${service} is not supported"
            fi
        fi
    done
    echo "[$($LOGDATE)] Services saved succesfully"
fi

##################################
# Backup folders
##################################

echo "[$($LOGDATE)] Backup folders"
mkdir ${WORKING_DIR}/folders
for backup_folder in ${FOLDERS_TO_BACKUP[*]}
do
    echo "[$($LOGDATE)] Backup ${backup_folder}"
    filter_folder=${backup_folder//\//_}
    cd ${backup_folder}
    if [ "${ONLY_SUBFOLDERS}" = "true" ]
    then
        mkdir ${WORKING_DIR}/folders/${filter_folder}
        for folder in $(find ${backup_folder} -mindepth 1 -maxdepth 1 -type d)
        do
                echo "[$($LOGDATE)] processing ${folder}"
                tar czf ${WORKING_DIR}/folders/${filter_folder}/$(basename ${folder}).tar.gz ./$(basename ${folder})
        done
    else
        tar czf ${WORKING_DIR}/folders/${filter_folder}.tar.gz .
    fi
done

echo "[$($LOGDATE)] Folders saved succesfully"

##################################
# Backup files
##################################

echo "[$($LOGDATE)] Backup files"
mkdir ${WORKING_DIR}/files
for backup_file in ${FILES_TO_BACKUP[*]}
do
    echo "[$($LOGDATE)] Backup ${backup_file}"
    filter_file=${backup_file//\//_}
    cp ${backup_file} ${WORKING_DIR}/files/${filter_file}
done

echo "[$($LOGDATE)] Files saved succesfully"

##################################
# Send the backup to remote
##################################

echo "[$($LOGDATE)] Create backup archive"

cd ${WORKING_DIR}
tar czf /tmp/backup_${SERVER}_${curday}.tar.gz .

echo "[$($LOGDATE)] Copy latest backup"
rclone --progress copy /tmp/backup_${SERVER}_${curday}.tar.gz ${REMOTE_NAME}:backup/${SERVER}

##################################
# Clean useless files
##################################

echo "[$($LOGDATE)] Remove old backup"
rclone --dry-run --min-age ${DAYS_TO_BACKUP}d delete ${REMOTE_NAME}:backup/${SERVER}
rclone --min-age ${DAYS_TO_BACKUP}d --progress delete ${REMOTE_NAME}:backup/${SERVER}

echo "[$($LOGDATE)] Clean local environment"
rm -rf ${WORKING_DIR} /tmp/backup_${SERVER}_${curday}.tar.gz

echo "[$($LOGDATE)] Backup done"

exit 0