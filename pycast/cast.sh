#!/bin/bash

if [ $# -ne 2 ]; then
  echo "$0 <url> <device>"
  exit 1
fi

docker run --rm -it --network host -e URL="$1" -e DEVICE="$2" huangw5/pycast
