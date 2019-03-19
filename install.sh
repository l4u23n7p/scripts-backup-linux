echo 'Install rclone'

cd /tmp 

curl https://rclone.org/install.sh | sudo bash

echo 'Configure remote'

rclone config

echo 'Configure cron task'

sudo crontab < <(sudo crontab -l ; echo "@daily cd $(dirname $(realpath $0)) && ./save.sh")

echo "Install completed"

exit 0