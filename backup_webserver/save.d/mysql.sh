if [ "${MYSQL_USER:-}" = "" ]
then
    MYSQL_USER=${DB_USER}
fi
if [ "${MYSQL_PASSWORD:-}" = "" ]
then
    MYSQL_PASSWORD=${DB_PASSWORD}
fi
                
for db in $(mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'show databases;' | grep -Ev "^(Database|mysql|information_schema|performance_schema|phpmyadmin|sys)$")
do
    echo "processing ${db}"
    mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} "${db}" | gzip > ${WORKING_DIR}/databases/mysql/${db}_$(date +%F).sql.gz
done

echo "processing all db"
mysqldump --opt -u${MYSQL_USER} -p${MYSQL_PASSWORD} --events --ignore-table=mysql.event --all-databases | gzip > ${WORKING_DIR}/databases/mysql/all_databases_$(date +%F).sql.gz