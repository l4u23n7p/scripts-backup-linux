cmd_import() {
    VOLUME_NAME="$1"
    DIR_PATH="$2"
    FILE_NAME="$3"

    if [ -z "$VOLUME_NAME" ] || [ -z "$DIR_PATH" ] || [ -z "$FILE_NAME" ]; then
        echo "[$($LOGDATE)] Error: Not enough arguments"
        return 1
    fi

    if ! docker volume inspect --format '{{.Name}}' "$VOLUME_NAME"; then
        echo "[$($LOGDATE)] Error: Volume $VOLUME_NAME does not exist"
        docker volume create "$VOLUME_NAME"
    fi

    if ! docker run --rm \
        -v "$VOLUME_NAME":/vackup-volume \
        -v "$DIR_PATH":/vackup \
        busybox \
        tar -xzf /vackup/"$FILE_NAME" -C /; then
        echo "[$($LOGDATE)] Error: Failed to start busybox container"
        return 1
    fi

    echo "[$($LOGDATE)] Successfully unpacked $FILE_NAME into volume $VOLUME_NAME"
}

echo "[$($LOGDATE)] Restore docker volumes"
mkdir ${WORKING_DIR}/volumes
for volume in ${VOLUMES_TO_BACKUP[*]}; do
    echo "[$($LOGDATE)] processing ${volume}"
    cmd_import ${volume} ${WORKING_DIR}/volumes ${volume}.tar.gz
done
echo "[$($LOGDATE)] Docker volumes restored succesfully"
