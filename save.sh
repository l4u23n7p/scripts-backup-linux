#!/bin/bash

# set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${ROOT}/$(basename "${BASH_SOURCE[0]}")"
BASE="$(basename ${FILE}.sh)"
curday=$(date +${DATE_FORMAT})
logdate="date -Iseconds"

echo "[$($logdate)] Import config"

source ${ROOT}/save.conf

##################################
# Create local working directory and collect all data
echo "[$($logdate)] Create working directory: ${WORKING_DIR}"

rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}
cd ${WORKING_DIR}

# Backup Database
if [ "${BACKUP_DB}" = "true" ]
then
    echo "[$($logdate)] Backup DB"
    mkdir ${WORKING_DIR}/databases
    for engine in ${DB_ENGINE_TO_BACKUP[*]}
    do
        if test -f "${ROOT}/save.d/engines/${engine}.sh"
        then
            mkdir ${WORKING_DIR}/databases/${engine}
            source "${ROOT}/save.d/engines/${engine}.sh"
        else
            echo "[$($logdate)] ${engine} is not supported"
        fi
    done
    echo "[$($logdate)] Databases saved succesfully"
fi


# Backup Service configuration
if [ "${BACKUP_SERVICES}" = "true" ]
then
    echo "[$($logdate)] Backup services"
    mkdir ${WORKING_DIR}/services
    for service in ${SERVICES_TO_BACKUP[*]}
    do
        echo "[$($logdate)] processing ${service}"
        if test -f "${ROOT}/save.d/services/${service}.sh"
        then
            source "${ROOT}/save.d/services/${service}.sh"
        else
            if test -d "/etc/${service}"
            then
                cd /etc
                tar czf ${WORKING_DIR}/services/${service}.tar.gz ./${service}
            else
                echo "[$($logdate)] ${service} is not supported"
            fi
        fi
    done
    echo "[$($logdate)] Services saved succesfully"
fi


echo "[$($logdate)] Backup folders"
# Backup folders
mkdir ${WORKING_DIR}/folders
for backup_folder in ${FOLDERS_TO_BACKUP[*]}
do
    echo "[$($logdate)] Backup ${backup_folder}"
    filter_folder=${backup_folder//\//_}
    cd ${backup_folder}
    if [ "${ONLY_SUBFOLDERS}" = "true" ]
    then
        mkdir ${WORKING_DIR}/folders/${filter_folder}
        for folder in $(find ${backup_folder} -mindepth 1 -maxdepth 1 -type d)
        do
                echo "[$($logdate)] processing ${folder}"
                tar czf ${WORKING_DIR}/folders/${filter_folder}/$(basename ${folder}).tar.gz ./$(basename ${folder})
        done
    else
        tar czf ${WORKING_DIR}/folders/${filter_folder}.tar.gz .
    fi
done

echo "[$($logdate)] Folders saved succesfully"

echo "[$($logdate)] Create backup archive"

cd ${WORKING_DIR}
tar czf /tmp/backup_${SERVER}_${curday}.tar.gz .

echo "[$($logdate)] Copy latest backup"
rclone --progress copy /tmp/backup_${SERVER}_${curday}.tar.gz ${REMOTE_NAME}:backup/${SERVER}

echo "[$($logdate)] Remove old backup"
rclone --dry-run --min-age ${DAYS_TO_BACKUP}d delete ${REMOTE_NAME}:backup/${SERVER}
rclone --min-age ${DAYS_TO_BACKUP}d --progress delete ${REMOTE_NAME}:backup/${SERVER}

echo "[$($logdate)] Clean local environment"
rm -rf ${WORKING_DIR} /tmp/backup_${SERVER}_${curday}.tar.gz

echo "[$($logdate)] Backup done"

exit 0