#!/bin/bash
if [ "$#" -ne 2 ]; then
  echo "Usage: build_and_make_installer.sh <image name> <panel type>"
  echo "Image names: barebone, phosh, plasma-mobile, lomiri"
  echo "Panel types: tianma, ebbg"
  exit 1
fi

source build.sh "$1"
source make_installer.sh "${1//-apps/}" "$2"
