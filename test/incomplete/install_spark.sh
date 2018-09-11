#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

function poll_build() {
    local name
    name=$1
    local tries=0
    local status
    local BUILDNUM


    set +e
    oc get buildconfig $name
    res=$?
    set -e
    if [ "$res" -ne 0 ]; then
       # this utility routine will end up getting run for some tests
       # that use an existing image and have no buildconfig as part
       # of the app deployment. If the bc just doesn't exist, return
       return
    fi

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
		    oc start-build $name
		    continue
		fi
	    fi
	    oc log buildconfig/$name | tail -100
	    set -e
	    oc delete buildconfig $name
	    oc delete is $name
	    set +e
	    oc delete dc $name
	    set -e
	    return 1
	else
	    break
	fi
    done
}

os::test::junit::declare_suite_start "install_spark"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
os::cmd::expect_success 'oc start-build spark --from-file="$RESOURCE_DIR"/spark-inputs'

poll_build spark

os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Attempting to install Spark'
os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Push successful'

os::test::junit::declare_suite_end
