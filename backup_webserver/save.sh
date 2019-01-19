#!/bin/bash

# set -o xtrace
set -o errexit
set -o nounset
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${ROOT}/$(basename "${BASH_SOURCE[0]}")"
BASE="$(basename ${FILE} .sh)"

source ${ROOT}/config.conf

##################################
# Create local working directory and collect all data
rm -rf ${WORKING_DIR}
mkdir ${WORKING_DIR}
cd ${WORKING_DIR}

# Backup Database
if [ "${BACKUP_DB}" ]
then
    mkdir ${WORKING_DIR}/databases
    for engine in ${DB_ENGINE[*]}
    do
        if test -f "${ROOT}/save.d/${engine}.sh"
        then
            mkdir ${WORKING_DIR}/databases/${engine}
            case $engine in
                'mysql')
                    if [ "${MYSQL_USER:-}" = "" ]
                    then
                        MYSQL_USER=${DB_USER}
                    fi
                    if [ "${MYSQL_PASSWORD:-}" = "" ]
                    then
                        MYSQL_PASSWORD=${DB_PASSWORD}
                    fi
                ;;
                *) echo ${engine} is not supported
                ;;
            esac
            
            source "${ROOT}/save.d/${engine}.sh"
        fi
    done
fi

# Backup folders
mkdir ${WORKING_DIR}/folders
for backup_folder in ${FOLDERS_TO_BACKUP[*]}
do
    for folder in $(find ${backup_folder} -mindepth 1 -maxdepth 1 -type d)
    do
            cd $(dirname ${folder})
            tar cJf ${WORKING_DIR}/folders/$(basename ${folder}).tar.xz $(basename ${folder})
            cd - > /dev/null
    done
done

# # Create base backup folder
# [ -z "$(megals --reload /Root/backup_${SERVER})" ] && megamkdir /Root/backup_${SERVER}

# # Remove old logs
# while [ $(megals --reload /Root/backup_${SERVER} | grep -E "/Root/backup_${SERVER}/[0-9]{4}-[0-9]{2}-[0-9]{2}$" | wc -l) -gt ${DAYS_TO_BACKUP} ]
# do
#         TO_REMOVE=$(megals --reload /Root/backup_${SERVER} | grep -E "/Root/backup_${SERVER}/[0-9]{4}-[0-9]{2}-[0-9]{2}$" | sort | head -n 1)
#         megarm ${TO_REMOVE}
# done

# # Create remote folder
# curday=$(date +%F)
# megamkdir /Root/backup_${SERVER}/${curday} 2> /dev/null

# # Backup now!!!
# megasync --reload --no-progress -l ${WORKING_DIR} -r /Root/backup_${SERVER}/${curday} > /dev/null

# # Kill DBUS session daemon (workaround)
# kill ${DBUS_SESSION_BUS_PID}
# rm -f ${DBUS_SESSION_BUS_ADDRESS}

# Clean local environment
# rm -rf ${WORKING_DIR}
exit 0