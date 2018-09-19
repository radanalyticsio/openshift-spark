#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

os::test::junit::declare_suite_start "deploy"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$SPARK_IMAGE"'

#check pods have been created
os::cmd::try_until_text 'oc get pods' 'worker'

os::cmd::try_until_text 'oc get pods' 'master'

# expose the service
os::cmd::expect_success 'oc expose service/master-webui'

# parse the ip
HOST=$(oc get route | grep master-webui | awk '{print $2;}')

os::cmd::try_until_text 'curl --silent "$HOST" | grep "Alive Workers" | sed "s,[^0-9],\\ ,g" | tr -d "[:space:]"' "^1$"

#checking the delpoyer pods are gone
os::cmd::try_until_text 'oc get pods -l openshift.io/deployer-pod-for.name' 'No resources found.'

#test deletion
os::cmd::try_until_success 'oc delete dc/worker'

os::cmd::try_until_success 'oc delete dc/master'

#check the pods have been deleted using a label
os::cmd::try_until_text 'oc get pods' 'No resources found.' $((25*second))

cleanup_app

os::test::junit::declare_suite_end
