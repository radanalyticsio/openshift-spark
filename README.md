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

# Customization

There are several ways to customize the construction and build process. This
project uses the [GNU Make tool](https://www.gnu.org/software/make/) for
the build workflow, see the `Makefile` for more information. For container
specification and construction, the
[Container image creation tool `concreate`](https://github.com/cekit/cekit) is
used as the primary point of investigation, see the `image.yaml` file for
more information.
