#!/usr/bin/env bash
set -e

DEVICE="/dev/sda1"
MOUNTPOINT="/home/deck/Volume"
NOTIFY_SEND="/usr/bin/notify-send"

sudo mkdir -p "$MOUNTPOINT"

if ! sudo mount -t ntfs3 "$DEVICE" "$MOUNTPOINT"; then
  $NOTIFY_SEND "Normal mount failed. Repairing..."
  sudo ntfsfix "$DEVICE"

  if ! sudo mount -t ntfs3 "$DEVICE" "$MOUNTPOINT"; then
    $NOTIFY_SEND "Mount failed. Please unplug the device and run CHKDSK on Windows."
    exit 1
  fi
fi

$NOTIFY_SEND "Mounted at $MOUNTPOINT"
exit 0
