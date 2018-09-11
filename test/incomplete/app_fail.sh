#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

function get_cluster_pod() {
    local count
    count=0

    set +e
    while true; do
        POD=$(oc get pod -l deploymentconfig=$1 --template='{{index .items 0 "metadata" "name"}}')
        if [ "$?" -eq 0 ]; then
            break
        fi
        echo Getting cluster pod for $1 failed, trying again
        oc get pods
        sleep 0.5
        count=$((count + 1))
        echo $count
        if [ "$count" -eq 120 ]; then
            return 1
        fi
    done
    set -e
}

os::test::junit::declare_suite_start "app_fail"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$SPARK_IMAGE"'

# If a user tries to use the image as a cluster image without completion, the usage script should run
get_cluster_pod master
os::cmd::try_until_text 'oc logs $POD' 'this is usage'

get_cluster_pod worker
os::cmd::try_until_text 'oc logs $POD' 'this is usage'

cleanup_app

os::test::junit::declare_suite_end
