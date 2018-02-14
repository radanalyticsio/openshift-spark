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
os::cmd::expect_success 'oc expose service/master-jolokia'

# parse the ip
HOST=$(oc get route | grep master-jolokia | awk '{print $2;}')/jolokia/
echo curling jolokia at $HOST

# check its up
os::cmd::try_until_text 'curl --silent --output /dev/null --write-out %{http_code} "$HOST"' '^200$' $((60*second))
