TARGET_APP_PATH=$1
TARGET_FILES=$(find $TARGET_APP_PATH -type f)
rm Procfile
touch Procfile
for f in $TARGET_FILES*
do
    FERRET_NAME=$(echo $f | sed -e 's:\./::' -e 's:[/.-]:_:g')
    echo "$FERRET_NAME: $f" >> Procfile
done