#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

os::test::junit::declare_suite_start "install_spark"

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'

poll_binary_build spark "$THIS" true

os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'

oc delete buildconfig spark

cleanup_app

os::test::junit::declare_suite_end
