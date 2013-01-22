TARGET_APP_PATH=$1
for f in $TARGET_APP_PATH 
do
    FERRET_NAME=$(echo $TARGET_APP_PATH | sed -e 's:\./::' -e 's:[/._]:-:g')
    Procfile << "$FERRET_NAME : $TARGET_APP_PATH/$f"
done
