cmd_export() {
    VOLUME_NAME="$1"
    DIR_PATH="$2"
    FILE_NAME="$3"

    if [ -z "$VOLUME_NAME" ] || [ -z "$DIR_PATH" ] || [ -z "$FILE_NAME" ]; then
        echo "[$($LOGDATE)] Error: Not enough arguments"
        return 1
    fi

    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; then
        echo "[$($LOGDATE)] Error: Volume $VOLUME_NAME does not exist"
        return 1
    fi

    if ! docker run --rm \
        -v "$VOLUME_NAME":/vackup-volume \
        -v "$DIR_PATH":/vackup \
        busybox \
        tar -zcf /vackup/"$FILE_NAME" /vackup-volume; then
        echo "Error: Failed to start busybox backup container"
        return 1
    fi

    echo "[$($LOGDATE)] Successfully tar'ed volume $VOLUME_NAME into file $FILE_NAME"
}

echo "[$($LOGDATE)] Backup docker volumes"
mkdir ${WORKING_DIR}/volumes
for volume in ${VOLUMES_TO_BACKUP[*]}; do
    echo "[$($LOGDATE)] processing ${volume}"
    cmd_export ${volume} ${WORKING_DIR}/volumes ${volume}.tar.gz
done
echo "[$($LOGDATE)] Docker volumes saved succesfully"
