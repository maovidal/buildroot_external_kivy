#!/bin/bash

set -e

BOARD_DIR=$BR2_EXTERNAL_MYRPI2CFG_PATH/board/raspberrypi2
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp ${BOARD_DIR}/cmdline.txt ${BINARIES_DIR}/rpi-firmware/cmdline.txt
cp ${BOARD_DIR}/config.txt ${BINARIES_DIR}/rpi-firmware/config.txt

rm -rf "${GENIMAGE_TMP}"

genimage                           \
    --rootpath "${TARGET_DIR}"     \
    --tmppath "${GENIMAGE_TMP}"    \
    --inputpath "${BINARIES_DIR}"  \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

exit $?
