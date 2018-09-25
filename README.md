[![Build status](https://travis-ci.org/radanalyticsio/openshift-spark.svg?branch=master)](https://travis-ci.org/radanalyticsio/openshift-spark)
[![Docker build](https://img.shields.io/docker/automated/radanalyticsio/openshift-spark.svg)](https://hub.docker.com/r/radanalyticsio/openshift-spark)
[![Layers info](https://images.microbadger.com/badges/image/radanalyticsio/openshift-spark.svg)](https://microbadger.com/images/radanalyticsio/openshift-spark)

# Apache Spark images for OpenShift

This repository contains several files for building
[Apache Spark](https://spark.apache.org) focused container images, targeted
for usage on [OpenShift Origin](https://openshift.org).

By default, it will build the following images into your local Docker
registry:

* `openshift-spark`, Apache Spark, Python 2.7
* `openshift-spark-py36`, Apache Spark, Python 3.6

For Spark versions, please see the `image.yaml` file.

# Instructions

## Build

Create all images and save them in the local Docker registry.

    make

## Push

Tag and push the images to the designated reference.

    make push SPARK_IMAGE=[REGISTRY_HOST[:REGISTRY_PORT]/]NAME[:TAG]

## Customization

There are several ways to customize the construction and build process. This
project uses the [GNU Make tool](https://www.gnu.org/software/make/) for
the build workflow, see the `Makefile` for more information. For container
specification and construction, the
[Container image creation tool `concreate`](https://github.com/cekit/cekit) is
used as the primary point of investigation, see the `image.yaml` file for
more information.

# Partial images without an Apache Spark distribution installed

This repository also supports building 'incomplete' versions of
the images which contain tooling for OpenShift but lack an actual
Spark distribution. An s2i workflow can be used with these partial
images to install a Spark distribution of a user's choosing.
This gives users an alternative to checking out the repository
and modifying build files if they want to run a custom
Spark distribution. By default, the partial images built will be

* `openshift-spark-inc`, Apache Spark, Python 2.7
* `openshift-spark-inc-py36`, Apache Spark, Python 3.6

## Build

To build the partial images, use make with Makefile.inc

    make -f Makefile.inc

## Push

Tag and push the images to the designated reference.

    make -f Makefile.inc push SPARK_IMAGE=[REGISTRY_HOST[:REGISTRY_PORT]/]NAME[:TAG]

## Image Completion

To produce a final image, a source-to-image build must be performed which takes
a Spark distribution as input. This can be done in OpenShift or locally using
the [s2i tool](https://github.com/openshift/source-to-image) if it's installed.
The final images created can be used just like the `openshfit-spark` and
`openshift-spark-py36` images described above.

To complete the Python 2.7 image using the [s2i tool](https://github.com/openshift/source-to-image)

    $ mkdir build_input
    $ wget https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz -O build_input/spark-2.3.0-bin-hadoop2.7.tgz
    $ wget https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz.md5 -O build_input/spark-2.3.0-bin-hadoop2.7.tgz.md5
    $ s2i build build_input radanalyticsio/openshift-spark-inc openshift-spark

To complete the Python 2.7 image using OpenShift, for example:

    $ oc new-build --name=openshift-spark --docker-image=radanalyticsio/openshift-spark-inc --binary
    $ oc start-build openshift-spark --from-file=https://archive.apache.org/dist/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz

    (note that the value of `--from-file` could also be the `build_input` directory from the s2i example above)

This will write the completed image to an imagestream called `openshift-spark` in the current project

# A 'usage' command for all images

Note that all of the images described here will respond to a 'usage' command for reference. For example

    $ docker run --rm openshift-spark:latest usage
