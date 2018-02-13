#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/create"

RESOURCE_DIR="$(dirname "${BASH_SOURCE}")/../resources"

os::cmd::expect_success 'oc create configmap test-config --from-file=$RESOURCE_DIR/config'

os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-spark-metrics-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$OPENSHIFT_SPARK_TEST_IMAGE" -p SPARK_METRICS_ON=jolokia'

# check the master has started the metrics
os::cmd::try_until_text 'oc logs dc/master' 'Starting master with jolokia metrics enabled'

# expose the service
os::cmd::expect_success 'oc expose service/master'

# parse the ip
HOST=$(oc get route | awk '{print $2;}')

# check its up
os::cmd::expect_success 'curl $HOST'
