[![Build status](https://travis-ci.org/radanalyticsio/openshift-spark.svg?branch=master)](https://travis-ci.org/radanalyticsio/openshift-spark)
[![Docker build](https://img.shields.io/docker/automated/radanalyticsio/openshift-spark.svg)](https://hub.docker.com/r/radanalyticsio/openshift-spark)
[![Layers info](https://images.microbadger.com/badges/image/radanalyticsio/openshift-spark.svg)](https://microbadger.com/images/radanalyticsio/openshift-spark)

# Apache Spark images for OpenShift

# Build

    make
Maybe you must edit the Dockerfile for insert some proxy definition.
for example, insert the following lines after ARG DISTRO_NAME:

    ENV http_proxy=http://192.168.1.1:8080
    ENV https_proxy=http://192.168.1.1:8080

    RUN echo "proxy=http://192.168.1.1:8080" >> /etc/yum.conf && \
    yum install -y epel-release tar java && \
    yum clean all


# Push

    make push SPARK_IMAGE=[REGISTRY_HOST/][USERNAME]
    
# Edit the template.yml file
- change the value of the SPARK_IMAGE (default: 10.193.127.18:5000/openshift/apachespark:latest)

# Insert the template to openshift
    oc create -f apachespark.yaml -n openshift
    oc delete template apache-spark -n openshift
