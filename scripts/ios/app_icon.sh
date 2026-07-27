#!/bin/sh

DEST_DIR_PATH="`pwd`/../../ios/AppIcon.icon"
SRC_DIR_PATH="`pwd`/../../assets/images/ios_icons"
mkdir -p "$DEST_DIR_PATH"

case $APP_IOS_TYPE in
	"mi-boveda")
    ICON_DIRECTORY="monerocom-app.icon"
    ;;
	"miboveda")
    ICON_DIRECTORY="miboveda-app.icon"
    ;;
esac

rm -rf $DEST_DIR_PATH
cp -r "$SRC_DIR_PATH/$ICON_DIRECTORY" "$DEST_DIR_PATH"