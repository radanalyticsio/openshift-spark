# Apache Spark master image for Docker

This image is the master node for a Spark cluster.

# Build

* ```docker build -t <name>/spark-master .```

# Use

* ```docker run -d --name spark-master --hostname spark-master <name>/spark-master```
