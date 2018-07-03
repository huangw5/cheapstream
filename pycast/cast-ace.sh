#!/bin/bash

if [ $# -ne 3 ]; then
  echo "$0 <server:port> <content_id> <device>"
  exit 1
fi

URL="http://$1/ace/manifest.m3u8?id=$2"
DEVICE="$3"

set -x
docker run --rm -it --network host -e URL="$URL" -e DEVICE="$DEVICE" huangw5/pycast
