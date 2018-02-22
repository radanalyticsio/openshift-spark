#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

source "$(dirname "${BASH_SOURCE}")/../common.sh"

RESOURCE_DIR="$(dirname "${BASH_SOURCE}")/../resources"

os::test::junit::declare_suite_start "cmd/create"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image

os::cmd::expect_success 'oc create configmap test-config --from-file=$RESOURCE_DIR/config'

os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$SPARK_IMAGE"'

os::cmd::try_until_text 'oc logs dc/master' 'Copying from /etc/config to /opt/spark/conf'

os::cmd::try_until_text 'oc logs dc/worker' 'Copying from /etc/config to /opt/spark/conf'

#test deletion
os::cmd::try_until_success 'oc delete dc/worker'

os::cmd::try_until_success 'oc delete dc/master'

#check the pods have been deleted using a label
os::cmd::try_until_text 'oc get pods' 'No resources found.' $((15*second))
