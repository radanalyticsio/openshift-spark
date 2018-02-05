op#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

RESOURCE_DIR="$(dirname "${BASH_SOURCE}")/../resources"

os::test::junit::declare_suite_start "cmd/create"

os::cmd::expect_success 'make build'

os::cmd::expect_success 'oc new-project config'

os::cmd::expect_success 'oc create configmap test-config --from-file=$RESOURCE_DIR/'

os::cmd::expect_success 'oc create -f $RESOURCE_DIR/test-template.yaml'

os::cmd::expect_success 'oc new-app --template=spark -p MASTER_NAME=master -p WORKER_NAME=worker'

os::cmd::try_until_text 'oc logs dc/master' 'DEBUG'

os::cmd::expect_success 'oc delete template --all'

os::cmd::expect_success 'oc delete pods --all'

os::cmd::expect_success 'oc delete project config'
