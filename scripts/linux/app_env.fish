#!/usr/bin/env fish

set -g APP_LINUX_NAME ""
set -g APP_LINUX_VERSION ""
set -g APP_LINUX_BUILD_NUMBER ""

set -g MIBOVEDA "miboveda"

set -g TYPES $MIBOVEDA
set -g APP_LINUX_TYPE $MIBOVEDA

if test -n "$argv[1]"
    set -g APP_LINUX_TYPE $argv[1]
end

set -g MIBOVEDA_NAME "Mi Bóveda"
set -g MIBOVEDA_VERSION "1.0.0"
set -g MIBOVEDA_BUILD_NUMBER 1

if not contains -- $APP_LINUX_TYPE $TYPES
    echo "Wrong app type."
    exit 1
end

switch $APP_LINUX_TYPE
    case $MIBOVEDA
        set -g APP_LINUX_NAME $MIBOVEDA_NAME
        set -g APP_LINUX_VERSION $MIBOVEDA_VERSION
        set -g APP_LINUX_BUILD_NUMBER $MIBOVEDA_BUILD_NUMBER
end

export APP_LINUX_TYPE
export APP_LINUX_NAME
export APP_LINUX_VERSION
export APP_LINUX_BUILD_NUMBER
