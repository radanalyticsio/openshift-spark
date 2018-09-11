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
wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz
wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz.md5
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
