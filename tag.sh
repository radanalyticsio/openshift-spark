#!/bin/bash

function usage() {
    echo
    echo "Creates a new tag for the current repo based on the spark version specified in image.yaml"
    echo "and the latest tag."
    echo
    echo "Usage: tag.sh"
    echo
    echo "optional arguments:"
    echo
    echo "  -h                  Show this message"
}

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

# Extract the current spark version from the image.yaml file
# Works by parsing the line following "name: sparkversion"
VER=$(sed -n '\@name: sparkversion@!b;n;p' image.yaml  | tr -d '[:space:]' | cut -d':' -f2)

echo Version from image.yaml is $VER

TAG=$(git describe --abbrev=0 --tags)

PREFIX=$(echo $TAG | cut -d'-' -f1)
BUILD=$(echo $TAG | cut -d'-' -f2)

# If we already have tags for Major.Minor version, just increment the build number
# If we don't already have tags for Major.Minor, start with build 1
newbranch=0
if [ "$PREFIX" == "$VER" ]; then
    TAG="$PREFIX-$((BUILD+1))"
else
    TAG="$VER-1"
    newbranch=1
fi

echo "Adding tag $TAG"
git tag "$TAG"
if [ "$?" -eq 0 ]; then
    echo Tag "$TAG" added, don\'t forget to push to upstream
    MAJORMINOR=$(echo $VER | cut -d'.' -f1,2)
    if [ "$newbranch" == 0 ]; then
	echo "Also, don't forget to rebase branch $MAJORMINOR on master if necessary"
    else
	echo "Also, looks like a new version of spark. Don't forget to create a $MAJORMINOR branch from master"
    fi
else
    echo Addition of tag "$TAG" failed
fi
