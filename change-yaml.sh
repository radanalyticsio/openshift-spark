#!/bin/bash

function usage() {
    echo

    echo "Changes the image.*.yaml file and adds it to the current commit (git add)"
    echo
    echo "Usage: change-yaml.sh [options] SPARK_VERSION"
    echo
    echo "required arguments"
    echo
    echo "  SPARK_VERSION      The spark version number, like 2.4.6"
    echo
    echo "optional arguments:"
    echo
    echo "  -h                  Show this message"
}

# Set the hadoop version
HVER=2.7

while getopts h opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift "$((OPTIND-1))"

if [ "$#" -lt 1 ]; then
    echo No spark version specified
    usage
    exit 1
fi

SPARK=$1

# Extract the current spark version from the image.yaml file
# Works by parsing the line following "name: sparkversion"
VER=$(sed -n '\@name: sparkversion@!b;n;p' image.yaml  | tr -d '[:space:]' | cut -d':' -f2)
if [ "$VER" == "$SPARK" ]; then
    echo "Nothing to do, spark version in image.yaml is already $SPARK"
    exit 0
fi

# Change spark distro and download urls
if [ ! -z ${SPARK+x} ]; then

    # TODO remove this download when sha512 support lands in upstream cekit (elmiko)
    if [ -f "/tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz" ]; then
        echo
        echo Using existing "/tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz", if this is not what you want delete it and run again
        echo
    else
        wget https://archive.apache.org/dist/spark/spark-${SPARK}/spark-${SPARK}-bin-hadoop${HVER}.tgz -O /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz
        if [ "$?" -ne 0 ]; then
            echo "Failed to download the specified version Spark archive"
            exit 1
        fi
    fi

    wget https://archive.apache.org/dist/spark/spark-${SPARK}/spark-${SPARK}-bin-hadoop${HVER}.tgz.sha512 -O /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz.sha512
    if [ "$?" -ne 0 ]; then
        echo "Failed to download the sha512 sum for the specified Spark version"
        exit 1
    fi

    # TODO remove this checksum calculation when sha512 support lands in upstream cekit (elmiko)
    calcsum=$(sha512sum /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz | cut -d" "  -f1)
    sum=$(cat  /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz.sha512 | tr -d [:space:] | cut -d: -f2 | tr [:upper:] [:lower:])
    if [ "$calcsum" != "$sum" ]; then
        echo "Failed to confirm authenticity of Spark archive, checksum mismatch"
        echo "sha512sum   : ${calcsum}"
        echo ".sha512 file: ${sum}"
        exit 1
    fi

	# Fix the url references
	sed -i "s@https://archive.apache.org/dist/spark/spark-.*/spark-.*-bin-@https://archive.apache.org/dist/spark/spark-${SPARK}/spark-${SPARK}-bin-@" image.yaml

    # TODO replace this with sha512 when it lands in upstream cekit (elmiko)
	# Fix the md5 sum references on the line following the url
    calcsum=$(md5sum /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz | cut -d" " -f1)
    sed -i '\@url: https://archive.apache.org/dist/spark/@!b;n;s/md5.*/md5: '$calcsum'/' image.yaml

    # Fix the spark version label
    sed -i '\@name: sparkversion@!b;n;s/value.*/value: '$SPARK'/' image.yaml

    # Fix the image version value (do this for incomplete as well)
    V=$(echo $SPARK | cut -d'.' -f1,2)
    sed -i 's@^version:.*-latest$@version: '$V'-latest@' image*.yaml
fi

git add image.yaml
