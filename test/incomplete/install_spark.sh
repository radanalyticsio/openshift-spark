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
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Installing spark native entrypoint'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Spark installed successfully'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Pushed'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function already_installed {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Attempting to install Spark'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Installing from tarball'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Spark installed successfully'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Pushed'

    # Now we should have an imagestream named spark
    SPARK_PULL=$(oc get is spark --template='{{index .status "dockerImageRepository"}}')
    os::cmd::expect_success 'oc new-build --name=already --docker-image="$SPARK_PULL" --binary'
    poll_binary_build already "$RESOURCE_DIR"/spark-inputs true
    os::cmd::expect_success_and_text 'oc log buildconfig/already' 'Spark is installed, nothing to do'

    os::cmd::expect_success 'oc delete buildconfig spark'
    os::cmd::expect_success 'oc delete buildconfig already'
}

function build_env_var {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary -e SPARK_URL=https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz -e SPARK_MD5_URL=https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz.md5'

    poll_binary_build spark

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Attempting to install Spark'
    os::cmd::try_until_success 'oc log buildconfig/spark | grep "Downloading.*spark-2.3.0-bin-hadoop2.7.tgz$"'
    os::cmd::try_until_success 'oc log buildconfig/spark | grep "Downloading.*spark-2.3.0-bin-hadoop2.7.tgz.md5$"'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Installing from tarball'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Spark installed successfully'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Pushed'
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
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Pushed'
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

function bad_submit {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs-bad-submit true

    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'Cannot run spark-submit, Spark install failed'
    os::cmd::expect_success_and_text 'oc log buildconfig/spark' 'no valid Spark distribution found'
    os::cmd::expect_success 'oc delete buildconfig spark'
}

function copy_nocopy {
    os::cmd::expect_success 'oc new-build --name=spark --docker-image="$SPARK_IMAGE" --binary'
    poll_binary_build spark "$RESOURCE_DIR"/spark-inputs-with-conf

    os::cmd::try_until_success 'oc log buildconfig/spark | grep "^Moving.*to /opt/spark/conf"'
    os::cmd::try_until_success 'oc log buildconfig/spark | grep "^Not moving.*/opt/spark/conf.*already exists"'
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

echo "++ build_env_var"
build_env_var

echo "++ already_installed"
already_installed

echo "++ bad_submit"
bad_submit

echo "++ copy_nocopy"
copy_nocopy

cleanup_app

os::test::junit::declare_suite_end
