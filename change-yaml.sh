#!/bin/bash

function usage() {
    echo

    echo "Changes the image.*.yaml file and adds it to the current commit (git add)"
    echo
    echo "Usage: change-yaml.sh [options] SPARK_VERSION"
    echo
    echo "required arguments"
    echo
    echo "  SPARK_VERSION      The spark version number, like 2.2.1"
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

    wget https://archive.apache.org/dist/spark/spark-${SPARK}/spark-${SPARK}-bin-hadoop${HVER}.tgz.sha512 -O /tmp/spark-${SPARK}-bin-hadoop${HVER}.tgz.sha512
    if [ "$?" -eq 0 ]; then

        sum=$(cat /tmp/spark-${SPARK}-bin-hadoop2.7.tgz.sha512 | cut -d':' -f 2 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

	# Fix the url references
	sed -i "s@https://archive.apache.org/dist/spark/spark-.*/spark-.*-bin-@https://archive.apache.org/dist/spark/spark-${SPARK}/spark-${SPARK}-bin-@" image.yaml

	# Fix the sha512 sum references on the line following the url
        sed -i '\@url: https://archive.apache.org/dist/spark/@!b;n;s/sha512.*/sha512: '$sum'/' image.yaml

	# Fix the spark version label
	sed -i '\@name: sparkversion@!b;n;s/value.*/value: '$SPARK'/' image.yaml

        # Fix the concreate version value
        V=$(echo $SPARK | cut -d'.' -f1,2)
        sed -i 's@^version:.*-latest$@version: '$V'-latest@' image.yaml

    else
        echo "Failed to get the sha512 sum for the specified spark version, the version $SPARK may not be a real version"
        exit 1
    fi
fi

git add image.yaml
