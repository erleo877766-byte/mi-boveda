#!/bin/bash

MONERO_COM=mi-boveda
CAKEWALLET=miboveda
HAVEN=haven
CONFIG_ARGS=""

case $APP_ANDROID_TYPE in
        $MONERO_COM)
                CONFIG_ARGS="--monero"
                ;;
        $CAKEWALLET)
                CONFIG_ARGS="--monero --bitcoin --ethereum --polygon --nano --bitcoinCash --solana --tron --wownero --zano --decred --dogecoin --base --zcash --arbitrum --bsc"
                ;;
esac

cd ../..
cp -rf pubspec_description.yaml pubspec.yaml
dart run tool/generate_pubspec.dart
flutter pub get
cd scripts/android
