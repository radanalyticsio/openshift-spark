docker build -t openshift-spark  .
export SPARK_IMAGE=docker.io/radanalyticsio/openshift-spark:2.2.0-prometheus-metrics
export LOCAL_IMAGE=openshift-spark
docker tag $LOCAL_IMAGE $SPARK_IMAGE
docker push $SPARK_IMAGE
 
