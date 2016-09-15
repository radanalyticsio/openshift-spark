# openshift-spark-py27-sti

The Makefile in this directory builds an openshift-spark image based
on the standard python27 s2i image (centos/python-27-centos7).

It does this by copying files from the parent directory and modifying
the ``FROM`` field in the local Dockerfile before building. The motivation
is to provide a python s2i builder which has Apache Spark installed
without having to manually maintain the Spark installation commands and
to guarantee that this image and an openshift-spark image built in
the parent directory contain the same version of spark.

## How to use this Makefile

The `clean`, `build`, `push`, `create`, and `destroy` targets are analagous
to the targets in the parent directory's Makefile.

By default the `push` target will tag the image as `project/openshift-spark-py27-sti`,
edit the Makefile and change `SPARK_IAMGE` to control this.

However, files must be copied from the parent directory before the
image may be built. To do this use `make artifacts`:

```
    $ make artifacts
    $ sudo make push
```

To refresh the files copied from the parent directory:

```
    $ make clean-artifacts
    $ make artifacts
```