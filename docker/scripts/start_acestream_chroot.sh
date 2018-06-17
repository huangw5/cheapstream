#!/bin/sh
PATH=/sbin:/usr/sbin:/bin:/usr/bin

ACEADDON=$(cd $(dirname "$0") && pwd)
ACECHROOT="androidfs"
PERMISSION=""
SYSNSPAWN=""

if [ $(id -u) != 0 ]; then
  PERMISSION=$(which sudo)
  if [ ! -x "$PERMISSION" ]; then
    echo "Without sudo and not a root. Exiting."
    exit 1
  fi
fi

if [ ! -d "$ACEADDON/$ACECHROOT" ]; then
  echo "Core acestream application is not found. Exiting."
  exit 1
fi

if [ ! -x "$ACEADDON/$ACECHROOT/system/bin/sh" ]; then
  echo "Some files are not executable (/bin/sh). Exiting"
  exit 1
fi

if [ ! -x "$ACEADDON/$ACECHROOT/data/data/org.acestream.media/files/python/bin/python" ]; then
  echo "Some files is not executable (/bin/python). Exiting"
  exit 1
fi

for d in $ACEADDON/$ACECHROOT/dev $ACEADDON/$ACECHROOT/proc $ACEADDON/$ACECHROOT/sys;
do
  mkdir -p "$d"
done

$PERMISSION mount -o bind /dev $ACEADDON/$ACECHROOT/dev
$PERMISSION mount -t proc proc $ACEADDON/$ACECHROOT/proc
$PERMISSION mount -t sysfs sysfs $ACEADDON/$ACECHROOT/sys

ACE_ARG="--client-console"

if [ -f $ACEADDON/acestream-user.conf ]; then
  . $ACEADDON/acestream-user.conf
  if [ -n "$ACE_USER_ARG" ]; then
    ACE_ARG="$ACE_ARG $ACE_USER_ARG"
  fi
fi

$PERMISSION chroot $ACEADDON/$ACECHROOT \
  /system/bin/sh /system/bin/acestream.sh $ACE_ARG

