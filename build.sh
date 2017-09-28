#!/bin/bash

# Written by Vasiliy Solovey, 2016

if [ $# -ne 1 ]; then
  echo "Usage: $0 <arm|x86>"
  exit 1
fi

ARCH=$1
if [ "$ARCH" == "arm" ]; then
  ARCH="armv7"
fi

ARCH_EXT=$ARCH
if [ "$ARCH_EXT" == "armv7" ]; then
  ARCH_EXT="armeabiv7a"
fi

echo $ARCH_EXT

BUILD_DIR="build_dir"
DIST_DIR="dist"
LATEST_ANDROID_ENGINE_URI="http://dl.acestream.org/products/acestream-engine/android/$ARCH/latest"

echo "Cleaning up..."
rm -r $BUILD_DIR
rm -r $DIST_DIR

mkdir $BUILD_DIR
cd $BUILD_DIR

pwd

echo "Downloading latest AceStream engine for Android..."
wget $LATEST_ANDROID_ENGINE_URI -O acestream.apk

echo "Unpacking..."
mkdir acestream_bundle
unzip -q acestream.apk -d acestream_bundle

echo "Extracting resources..."
mkdir acestream_engine
unzip -q acestream_bundle/res/raw/"$ARCH_EXT"_private_py.zip -d acestream_engine
unzip -q acestream_bundle/res/raw/"$ARCH_EXT"_private_res.zip -d acestream_engine
unzip -q acestream_bundle/res/raw/public_res.zip -d acestream_engine

echo "Patching Python..."
mkdir python27
unzip -q acestream_engine/python/lib/python27.zip -d python27
cp -r -f ../mods/python27/* python27/

echo "Patching AceStream engine..."
cp -f ../mods/acestreamengine/* acestream_engine/
chmod +x acestream_engine/python/bin/python

echo "Bundling Python..."
cd python27
zip -q -r python27.zip *
mv -f python27.zip ../acestream_engine/python/lib/
cd ..

echo "Making distributable..."
cd ..
mkdir $DIST_DIR
mkdir $DIST_DIR/androidfs
cp -r chroot/* $DIST_DIR/androidfs/
cp -r -f platform/$1/* $DIST_DIR/androidfs/
cp scripts/start_acestream.sh $DIST_DIR/
cp scripts/start_acestream_chroot.sh $DIST_DIR/
cp scripts/stop_acestream.sh $DIST_DIR/
cp scripts/acestream-user.conf $DIST_DIR/
cp scripts/acestream.sh $DIST_DIR/androidfs/system/bin/
mv $BUILD_DIR/acestream_engine/* $DIST_DIR/androidfs/data/data/org.acestream.media/files/

echo "Building docker image..."
docker build -t huangw5/cheapstream -t huangw5/cheapstream:$(date +%Y%m%d%H%M%S) . -f Dockerfile.${ARCH}

echo "Done! To start the engine, run:"
echo "  docker run --privileged -it --rm -p 6878:6878 huangw5/cheapstream"
