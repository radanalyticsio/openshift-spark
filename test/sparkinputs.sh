#!/usr/bin/env bash

TOP_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"` | grep -o '.*/openshift-spark/')
BUILD_DIR=$TOP_DIR/openshift-spark-build

fullname=$(find $BUILD_DIR -name spark-[0-9.]*\.tgz)

filename=$(basename $fullname)
version=$(echo $filename | cut -d '-' -f2)
mkdir -p $TOP_DIR/test/resources/spark-inputs
pushd $TOP_DIR/test/resources/spark-inputs
#wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz
wget https://archive.apache.org/dist/spark/spark-$version/spark-$version-bin-hadoop2.7.tgz.md5
echo "spark-$version-bin-hadoop2.7.tgz: FF FF FF FF FF FF CA FE  BE EF CA FE BE EF CA FE" > spark-$version-bin-hadoop2.7.tgz.bad
popd
