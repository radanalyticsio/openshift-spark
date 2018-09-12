#!/usr/bin/env bash

TOP_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"` | grep -o '.*/openshift-spark/')
BUILD_DIR=$TOP_DIR/openshift-spark-build

# See what spark version the image build used
fullname=$(find $BUILD_DIR -name spark-[0-9.]*\.tgz)

# Download the same version to use as a binary build input
filename=$(basename $fullname)
version=$(echo $filename | cut -d '-' -f2)
mkdir -p $TOP_DIR/test/resources/spark-inputs
pushd $TOP_DIR/test/resources/spark-inputs
if ! [ -f "spark-$version-bin-hadoop2.7.tgz" ]; then
    wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz
fi
if ! [ -f "spark-$version-bin-hadoop2.7.tgz.md5" ]; then
    wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz.md5
fi
echo "spark-$version-bin-hadoop2.7.tgz: FF FF FF FF FF FF CA FE  BE EF CA FE BE EF CA FE" > spark-$version-bin-hadoop2.7.tgz.bad
popd

# Make a fake tarball that is missing spark-submit
mkdir -p $TOP_DIR/test/resources/spark-inputs-no-submit
pushd $TOP_DIR/test/resources/spark-inputs-no-submit
mkdir spark-$version-bin-hadoop2.7
touch spark-$version-bin-hadoop2.7/foo
tar -czf spark-$version-bin-hadoop2.7.tgz spark-$version-bin-hadoop2.7
rm -rf spark-$version-bin-hadoop2.7
popd

# Make a fake tarball with a spark-submit that returns an error
mkdir -p $TOP_DIR/test/resources/spark-inputs-bad-submit
pushd $TOP_DIR/test/resources/spark-inputs-bad-submit
mkdir -p spark-$version-bin-hadoop2.7/bin
echo "#!/bin/bash" > spark-$version-bin-hadoop2.7/bin/spark-submit
echo "exit 1" >> spark-$version-bin-hadoop2.7/bin/spark-submit
chmod +x spark-$version-bin-hadoop2.7/bin/spark-submit
tar -czf spark-$version-bin-hadoop2.7.tgz spark-$version-bin-hadoop2.7
rm -rf spark-$version-bin-hadoop2.7
popd

# Make a fake tarball with a spark-submit that returns success
# Also include some config files so we can test copy-if-not-overwrite
mkdir -p $TOP_DIR/test/resources/spark-inputs-with-conf
pushd $TOP_DIR/test/resources/spark-inputs-with-conf
mkdir -p spark-$version-bin-hadoop2.7/bin
echo "#!/bin/bash" > spark-$version-bin-hadoop2.7/bin/spark-submit
echo "exit 0" >> spark-$version-bin-hadoop2.7/bin/spark-submit
chmod +x spark-$version-bin-hadoop2.7/bin/spark-submit
mkdir -p spark-$version-bin-hadoop2.7/conf
touch spark-$version-bin-hadoop2.7/conf/spark-defaults.conf
touch spark-$version-bin-hadoop2.7/conf/log4j.properties
tar -czf spark-$version-bin-hadoop2.7.tgz spark-$version-bin-hadoop2.7
rm -rf spark-$version-bin-hadoop2.7
popd
