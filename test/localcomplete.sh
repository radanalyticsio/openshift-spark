#!/bin/bash

# This script creates completed versions of the incomplete images
# and tags them into the local docker daemon so that the "completed"
# suite of tests can be run on them (the same tests are run on the
# "full" images as well)

function poll_binary_build() {
    local name=$1
    local tries=0
    local status
    local BUILDNUM

    oc start-build $name --from-file=$RESOURCE_DIR/spark-inputs

    while true; do
        BUILDNUM=$(oc get buildconfig $name --template='{{index .status "lastVersion"}}')
	if [ "$BUILDNUM" == "0" ]; then
	    # Buildconfig is brand new, lastVersion hasn't been updated yet
	    status="starting"
	else
            status=$(oc get build "$name"-$BUILDNUM --template="{{index .status \"phase\"}}")
	fi
	if [ "$status" == "starting" ]; then
	    echo Build for $name is spinning up, waiting ...
	    sleep 5
	elif [ "$status" != "Complete" -a "$status" != "Failed" -a "$status" != "Error" ]; then
	    echo Build for $name-$BUILDNUM status is $status, waiting ...
	    sleep 10
	elif [ "$status" == "Failed" -o "$status" == "Error" ]; then
	    set +e
	    oc log buildconfig/$name | grep "Pushing image"
	    if [ "$?" -eq 0 ]; then
		tries=$((tries+1))
		if [ "$tries" -lt 5 ]; then
		    echo Build failed on push, retrying
		    sleep 5
		    oc start-build $name --from-file=$RESOURCE_DIR/spark-inputs
		    continue
		fi
	    fi
	    oc log buildconfig/$name | tail -100
	    set -e
	    return 1
	else
	    echo Build for $name-$BUILDNUM status is $status, returning
	    break
	fi
    done
}

RESOURCE_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"` | grep -o '.*/openshift-spark/test')/resources

oc new-build --name=$2 --docker-image=$1 --binary

poll_binary_build $2 

id=$(docker images | grep $2 | head -n1 | awk '{print $3}')
echo docker tag "$id" "$2":latest
docker tag "$id" $2:latest
