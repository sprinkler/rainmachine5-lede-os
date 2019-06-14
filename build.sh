#!/bin/sh

BUILD=1
BUILD_CLEAN=1
SYNC_FACTORY=1
AWS_SYNC=1

PACKAGES_DIR="bin/targets/ramips/mt7688/packages"
LAN_UPDATE_DIR="/mnt/rainmachine-updates/rainmachine5"
LAN_IMAGE_DIR="/mnt/rainmachine-updates/sprinkler5"
IMAGE_17_VALVES="rainmachine5-17.01.0-r3205-59508e3-ramips-mt7688-LinkIt7688-jffs2-64k-sysupgrade.bin"

BUILD_ID=$(date +%s)
DATESTR=$(date +%F)

if [ $BUILD_CLEAN -eq 1 ]; then
    echo "Cleaning RainMachine5"
    mv ${PACKAGES_DIR} ${PACKAGES_DIR}-${BUILD_ID}
    #make clean
fi
if [ $BUILD -eq 1 ]; then
    echo "Building RainMachine5"
    make V=s > build.log 2>&1
fi

if [ $? -ne 0 ]; then
    echo "Building failed check build.log for errors"
    exit 1
fi

echo "Sync update package to remote servers"

if [ ! -d ${LAN_UPDATE_DIR} ]; then
    echo "LAN update path not mounted ! Aborting sync"
    exit 2
else
    rm ${LAN_UPDATE_DIR}/*
    echo " * Sync packages to LAN"
    cp -a ${PACKAGES_DIR}/* ${LAN_UPDATE_DIR}
    echo " * Sync 17 valves image to LAN"
    cp -a bin/targets/ramips/mt7688/${IMAGE_17_VALVES} ${LAN_IMAGE_DIR}/17valves/lks7688_16valves_${DATESTR}.img
    if [ $SYNC_FACTORY -eq 1 ]; then
	echo " * Sync 17 valves factory image to LAN"
	cp -a bin/targets/ramips/mt7688/${IMAGE_17_VALVES} ${LAN_IMAGE_DIR}/17valves/factory/lks7688_16valves_${DATESTR}.img
    fi
fi


if [ $AWS_SYNC -eq 1 ]; then
    echo " * Copy Alpha to AWS"
    aws s3 cp ${PACKAGES_DIR}/ s3://updates3.rainmachine.com/rainmachine5-alpha/ --region=us-west-2 --metadata "timestamp=$BUILD_ID" --recursive
fi
