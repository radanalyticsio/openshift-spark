#!/bin/bash

SPARK_TEST_IMAGE=${SPARK_TEST_IMAGE:-}

SPARK_TEST_LOCAL_IMAGE=${SPARK_TEST_LOCAL_IMAGE:-true}

# This is all for dealing with registries. External registry requires creds other than the current login
SPARK_TEST_INTEGRATED_REGISTRY=${SPARK_TEST_INTEGRATED_REGISTRY:-}
SPARK_TEST_EXTERNAL_REGISTRY=${SPARK_TEST_EXTERNAL_REGISTRY:-}
SPARK_TEST_EXTERNAL_USER=${SPARK_TEST_EXTERNAL_USER:-}
SPARK_TEST_EXTERNAL_PASSWORD=${SPARK_TEST_EXTERNAL_PASSWORD:-}

if [ -z "$SPARK_TEST_IMAGE" ]; then
    if [ "$SPARK_TEST_LOCAL_IMAGE" == true ]; then
        SPARK_TEST_IMAGE=spark-testimage:latest
    else
        SPARK_TEST_IMAGE=docker.io/radanalyticsio/openshift-spark:latest
    fi
fi

function print_test_env {
    echo Using image $SPARK_TEST_IMAGE

    if [ "$SPARK_TEST_LOCAL_IMAGE" != true ]; then
	echo SPARK_TEST_LOCAL_IMAGE = $SPARK_TEST_LOCAL_IMAGE, spark image is external, ignoring registry env vars
    elif [ -n "$SPARK_TEST_EXTERNAL_REGISTRY" ]; then
        echo Using external registry $SPARK_TEST_EXTERNAL_REGISTRY
        if [ -z "$SPARK_TEST_EXTERNAL_USER" ]; then
            echo "Error: SPARK_TEST_EXTERNAL_USER not set!"
	    exit 1
        else
	    echo Using external registry user $SPARK_TEST_EXTERNAL_USER
        fi
        if [ -z "$SPARK_TEST_EXTERNAL_PASSWORD" ]; then
            echo "SPARK_TEST_EXTERNAL_PASSWORD not set, assuming current docker login"
        else
            echo External registry password set
        fi
    elif [ -n "$SPARK_TEST_INTEGRATED_REGISTRY" ]; then
        echo Using integrated registry $SPARK_TEST_INTEGRATED_REGISTRY
    else
        echo Not using external or integrated registry
    fi
}
print_test_env

function make_image {
    # The ip address of an internal/external registry may be set to support running against
    # an openshift that is not "oc cluster up" when using images that have been built locally.
    # In the case of "oc cluster up", the docker on the host is available from openshift so
    # no special pushes of images have to be done.
    # In the case of a "normal" openshift cluster, a local image we'll use for build has to be
    # available from the designated registry.
    # If we're using an image already in an external registry, openshift can pull it from
    # there and we don't have to do anything.
    local user=
    local password=
    local pushproj=
    local pushimage=
    local registry=
    if [ "$SPARK_TEST_LOCAL_IMAGE" == true ]; then
	if [ -n  "$SPARK_TEST_EXTERNAL_REGISTRY" ]; then
	    user=$SPARK_TEST_EXTERNAL_USER
	    password=$SPARK_TEST_EXTERNAL_PASSWORD
	    pushproj=$user
	    pushimage=scratch-openshift-spark
	    registry=$SPARK_TEST_EXTERNAL_REGISTRY
	elif [ -n "$SPARK_TEST_INTEGRATED_REGISTRY" ]; then
	    user=$(oc whoami)
	    password=$(oc whoami -t)
	    pushproj=$PROJECT
	    pushimage=oshinko-webui
	    registry=$SPARK_TEST_INTEGRATED_REGISTRY
	fi
    fi
    if [ -n "$registry" ]; then
	set +e
	docker login --help | grep email &> /dev/null
	res=$?
	set -e
	if [ -n "$password" ] && [ -n "$user" ]; then
	    if [ "$res" -eq 0 ]; then
		docker login -u ${user} -e jack@jack.com -p ${password} ${registry}
	    else
		docker login -u ${user} -p ${password} ${registry}
	    fi
	fi
	docker tag ${SPARK_TEST_IMAGE} ${registry}/${pushproj}/${pushimage}
	docker push ${registry}/${pushproj}/${pushimage}
	SPARK_IMAGE=${registry}/${pushproj}/${pushimage}
    else
	SPARK_IMAGE=$SPARK_TEST_IMAGE
    fi
}
