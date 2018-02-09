#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/create"

RESOURCE_DIR="$(dirname "${BASH_SOURCE}")/../resources"

os::cmd::expect_success 'oc create -f "$RESOURCE_DIR"/test-template.yaml'

os::cmd::expect_success 'oc new-app --template=spark -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE="$OPENSHIFT_SPARK_TEST_IMAGE"'

#check pods have been created
os::cmd::try_until_text 'oc get pods' 'worker'

os::cmd::try_until_text 'oc get pods' 'master'
#check the workers have registered with the master
os::cmd::try_until_text 'oc logs dc/master' 'Registering worker'

os::cmd::try_until_text 'oc logs dc/worker' 'Worker: Successfully registered with master'

#checking the delpoyer pods are gone
os::cmd::try_until_text 'oc get pods -l openshift.io/deployer-pod-for.name' 'No resources found.'

#test deletion
os::cmd::try_until_success 'oc delete dc/worker'

os::cmd::try_until_success 'oc delete dc/master'

#check the pods have been deleted using a label
os::cmd::try_until_text 'oc get pods' 'No resources found.' $((15*second))
