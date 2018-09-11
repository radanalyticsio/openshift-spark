#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

os::test::junit::declare_suite_start "deploy_prom"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-spark-metrics-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$SPARK_IMAGE" -p SPARK_METRICS_ON=prometheus'

# check the master has started the metrics
os::cmd::try_until_text 'oc logs dc/master' 'Starting master with prometheus metrics enabled'

# expose the service
os::cmd::expect_success 'oc expose service/master-prometheus'

# parse the ip
HOST=$(oc get route | grep master-prometheus | awk '{print $2;}')/metrics
echo curling prometheus at $HOST

# check its up
os::cmd::try_until_text 'curl --silent --output /dev/null --write-out %{http_code} "$HOST"' '^200$' $((60*second))

cleanup_app

os::test::junit::declare_suite_end
