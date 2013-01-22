TARGET_APP_PATH=$1
TARGET_FILES=$(find $TARGET_APP_PATH -type f)
SCALE_CMD=""
for f in $TARGET_FILES*
do
    FERRET_NAME=$(echo $f | sed -e 's:\./::' -e 's:[/._]:_:g')
    SCALE_CMD="$SCALE_CMD $FERRET_NAME=$2"
done
echo $SCALE_CMD
heroku scale $SCALE_CMD