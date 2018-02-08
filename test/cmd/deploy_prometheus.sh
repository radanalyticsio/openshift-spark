#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/create"

os::cmd::expect_success 'make build'

TEST_DIR=$(pwd)

os::cmd::expect_success 'oc new-project prom'

os::cmd::expect_success 'oc create -f "$TEST_DIR"/spark-metrics-template.yaml'

os::cmd::expect_success 'oc new-app --template=spark -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_METRICS_ON=prometheus'

os::cmd::try_until_text 'oc get pods' 'worker'

os::cmd::try_until_text 'oc get pods' 'master'
#check the workers have registered with the master
os::cmd::try_until_text 'oc logs dc/master' 'Registering worker'

os::cmd::try_until_text 'oc logs dc/worker' 'Worker: Successfully registered with master'

os::cmd::try_until_success 'oc delete dc/worker'

os::cmd::try_until_success 'oc delete dc/master'

os::cmd::expect_failure 'oc get dc/worker'

os::cmd::expect_failure 'oc get dc/master'

os::cmd::expect_success 'oc delete template --all'

os::cmd::expect_success 'oc delete pods --all'

os::cmd::expect_success 'oc delete project prom'
