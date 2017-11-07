docker build -t openshift-spark  .
export SPARK_IMAGE=docker.io/analyticsci/openshift-spark:v2.1.0-metrics-prometheus
export LOCAL_IMAGE=openshift-spark
docker tag $LOCAL_IMAGE $SPARK_IMAGE
docker push $SPARK_IMAGE
 
