#!/bin/bash

APP_PROPERTIES_PATH=./../../android/app.properties

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

touch $APP_PROPERTIES_PATH

printf "id=%s\nname=%s\n" "${APP_ANDROID_BUNDLE_ID}" "${APP_ANDROID_NAME}" > $APP_PROPERTIES_PATH