#!/bin/bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${ROOT}/$(basename "${BASH_SOURCE[0]}")"
BASE="$(basename ${FILE}.sh)"

echo "Import config"

source ${ROOT}/install.conf

printf '%s\n\n' "Install rclone"

cd /tmp 

curl https://rclone.org/install.sh | sudo bash

cd - > /dev/null

printf '%s\n\n' "Configure remote"

sudo rclone config

printf '\n\033[41;3m%s\033[0m\n\n' "Don't forget to edit save.conf with the remote name to use"

if test -f /etc/logrotate.conf
then
    printf '%s\n' "Configure logrotate"

    if test -f /etc/logrotate.d/backup
    then
        printf '%s\n\n' 'Logrotate configuration already exist'
    else
        sudo bash -c "echo -e '${LOGFILE} {\n\tdaily\n\tmissingok\n\trotate 14\n\tcompress\n\tnotifempty\n\tcreate 640\n\tdateext\n}' > /etc/logrotate.d/backup"
        printf '%s\n\n' 'Logrotate configured'
    fi
else
    printf '%s\n\n' "Logrotate not install"
fi

echo "Do you wish to install cron task?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) do_cron=true; break;;
        No ) do_cron=false; break;;
    esac
done

if [ "${do_cron}" = true ]
then
    echo 'Configure cron task'

    cron_task="@daily ${ROOT}/save.sh >> ${LOGFILE} 2>&1"

    sudo crontab -l 2> /dev/null | grep "${cron_task}" 2>&1 > /dev/null

    cron_exist=$?

    case "${cron_exist}" in

    0)  echo 'Cron task already exist'
        ;;

    1)  (sudo crontab -l 2> /dev/null; echo $cron_task) | sudo crontab -
        echo 'Cron task added'
        ;;
    
    2)  echo 'Error when checking cron task existence'
        exit 2
        ;;
    
    *)  echo "I don't known why i'm doing this"
        exit 3
        ;;
    esac
else
    echo 'Skip cron task'
fi

echo "Install completed"

exit 0