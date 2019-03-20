#!/bin/bash

# set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${ROOT}/$(basename "${BASH_SOURCE[0]}")"
BASE="$(basename ${FILE}.sh)"
curday=$(date +%F)
logfile="/var/log/backup_mega_${curday}"

echo "Import config"

source ${ROOT}/save.conf

##################################
# Create local working directory and collect all data
echo "Create working directory: ${WORKING_DIR}"

rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}
cd ${WORKING_DIR}

# Backup Database
if [ "${BACKUP_DB}" = "true" ]
then
    echo "Backup DB"
    mkdir ${WORKING_DIR}/databases
    for engine in ${DB_ENGINE_TO_BACKUP[*]}
    do
        if test -f "${ROOT}/save.d/${engine}.sh"
        then
            mkdir ${WORKING_DIR}/databases/${engine}
            source "${ROOT}/save.d/${engine}.sh"
        else
            echo ${engine} is not supported
        fi
    done
    echo "Databases saved succesfully"
fi


# Backup Service configuration
if [ "${BACKUP_SERVICES}" = "true" ]
then
    echo "Backup services"
    mkdir ${WORKING_DIR}/services
    for service in ${SERVICES_TO_BACKUP[*]}
    do
        echo "processing ${service}"
        if test -d "/etc/${service}"
        then
            cd /etc
            tar czf ${WORKING_DIR}/services/${service}.tar.gz ./${service}
        else
            if test -f "${ROOT}/conf.d/${service}.sh"
            then
                source "${ROOT}/save.d/${service}.sh"
            else
                echo ${service} is not supported
            fi
        fi
    done
    echo "Services saved succesfully"
fi


echo "Backup folders"
# Backup folders
mkdir ${WORKING_DIR}/folders
for backup_folder in ${FOLDERS_TO_BACKUP[*]}
do
    echo "Backup ${backup_folder}"
    filter_folder=${backup_folder//\//_}
    cd ${backup_folder}
    if [ "${ONLY_SUBFOLDERS}" = "true" ]
    then
        mkdir ${WORKING_DIR}/folders/${filter_folder}
        for folder in $(find ${backup_folder} -mindepth 1 -maxdepth 1 -type d)
        do
                echo "processing ${folder}"
                tar czf ${WORKING_DIR}/folders/${filter_folder}/$(basename ${folder}).tar.gz ./$(basename ${folder})
        done
    else
        tar czf ${WORKING_DIR}/folders/${filter_folder}.tar.gz .
    fi
done

echo "Folders saved succesfully"

echo "Create backup archive"

cd ${WORKING_DIR}
tar czf /tmp/backup_${SERVER}_${curday}.tar.gz .

echo "Copy latest backup"
rclone --progress copy /tmp/backup_${SERVER}_${curday}.tar.gz ${REMOTE_NAME}:backup/${SERVER}

echo "Remove old backup"
rclone --dry-run --min-age ${DAYS_TO_BACKUP}d delete ${REMOTE_NAME}:backup/${SERVER}
rclone --min-age ${DAYS_TO_BACKUP}d --progress delete ${REMOTE_NAME}:backup/${SERVER}

echo "Clean local environment"
rm -rf ${WORKING_DIR} /tmp/backup_${SERVER}_${curday}.tar.gz

echo "Backup done"
exit 0