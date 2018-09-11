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
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Installing from tarball'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Spark installed successfully'
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
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function build_from_directory {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs/*.tgz

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Attempting to install Spark'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Installing from directory'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Spark installed successfully'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Push successful'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function tarball_no_submit {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs-no-submit true

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Ignoring tarball.*no spark-submit'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function directory_no_submit {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs-no-submit/*.tgz true

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Ignoring directory.*no spark-submit'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function build_bad_tarball {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$THIS" true

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Ignoring.*not a tar archive'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

# Handles registries, etc, and sets SPARK_IMAGE to the right value
make_image
make_configmap

echo "++ build_md5"
build_md5

echo "++ build_md5 (md5 deleted)"
md5=$(find $RESOURCE_DIR/spark-inputs -name "*.md5")
rm $md5
skip_app=true
build_md5 $skip_app

echo "++ build_bad_md5"
mv $RESOURCE_DIR/spark-inputs/$(basename $md5 .md5).bad $md5
build_bad_md5
rm $md5

echo "++ build_from_directory"
build_from_directory

echo "++ tarball_no_submit"
tarball_no_submit

echo "++ directory_no_submit"
directory_no_submit

echo "++ build_bad_tarball"
build_bad_tarball

cleanup_app

os::test::junit::declare_suite_end
