#!/bin/bash
THIS=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)
TOP_DIR=$(echo $THIS | grep -o '.*/openshift-spark')

source $TOP_DIR/hack/lib/init.sh
trap os::test::junit::reconcile_output EXIT

source $TOP_DIR/test/common.sh
RESOURCE_DIR=$TOP_DIR/test/resources

os::test::junit::declare_suite_start "install_spark"

function build_md5 {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Attempting to install Spark'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Push successful'

    if [ "$#" -ne 1 ] || [ "$1" != "true" ]; then
        # Now we should have an imagestream named spark
        SPARK_PULL=$(oc get is spark --template='{{index .status "dockerImageRepository"}}')
        os::cmd::expect_success 'oc new-app --file=$RESOURCE_DIR/test-template.yaml -p MASTER_NAME=master -p WORKER_NAME=worker -p SPARK_IMAGE=$SPARK_PULL'

        get_cluster_pod master
        os::cmd::try_until_text 'oc logs $POD' 'Starting.*master'

        get_cluster_pod worker
        os::cmd::try_until_text 'oc logs $POD' 'Starting.*worker'
    fi
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function build_bad_md5 {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs true

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'md5sum did not match'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

echo "++ build with md5"
#build_md5

echo "++ build without md5"
echo $RESOURCE_DIR
find $RESOURCE_DIR -name "*.md5"
md5=$(find $RESOURCE_DIR/spark-inputs -name "*.md5")
rm $md5
skip_app=true
build_md5 $skip_app

echo "++ build with bad md5"
mv $RESOURCE_DIR/spark-inputs/$(basename $md5 .md5).bad $md5
build_bad_md5
rm $md5

cleanup_app

os::test::junit::declare_suite_end
