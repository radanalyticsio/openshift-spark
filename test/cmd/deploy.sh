#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/create"

source "$(dirname "${BASH_SOURCE}")/../common.sh"

RESOURCE_DIR="$(dirname "${BASH_SOURCE}")/../resources"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image

os::cmd::expect_success 'oc create configmap test-config --from-file=$RESOURCE_DIR/config'

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
os::cmd::try_until_text 'oc get pods' 'No resources found.' $((15*second))
