#!/bin/bash

if [ $# -ne 2 ]; then
  echo "$0 <url> <device>"
  exit 1
fi

URL="$1"
DEVICE="$2"

set -x
docker run --rm -it --network host -e URL="$URL" -e DEVICE="$DEVICE" huangw5/pycast
