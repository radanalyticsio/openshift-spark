# Updating the base image Spark version

This document describes the general workflow for updating the Apache Spark
version present in the base image. This guide follows the process for
installing the default binary archives as distributed by the
[Spark project](https://spark.apache.org).

## prerequisites

* shell access
* an editor available
* access to the `docker` command line tool and a registry (for testing)
* [cekit](https://cekit.readthedocs.io/en/latest/) available

## procedure

### update the version numbers

1. update version and download link in `image.yaml`
1. update version in `image-inc.yaml` (to keep consistent versioning)

There is a script name `change-yaml.sh` that will automate this process,
invoke it by type the script name followed by the desired version. For
example, if you were creating an update for version `3.0.0` of Spark, you
would type the following:

```
./change-yaml.sh 3.0.0
```

### rebuild generated files

1. remove the generated cekit files for the previous version.
   ```
   make clean-context
   make -f Makefile.inc clean-context
   ```
1. generate the new cekit files. these will be the artifacts for image
   creation.
   ```
   make context
   make -f Makefile.inc context
   ```
1. zero the archive files. as these files are currently checked in to the
   repository it is important to zero out the archive files. they will be
   re-downloaded during the image constructions phase.
   ```
   make zero-tarballs
   ```

This process is also captured in a script file named `make-build-dir.sh`, it
automates the process of cleaning and then regenerating the cekit files
and Spark binaries. The script requires no parameters and it will attempt to
add the updated files to the current git staging process.

At this point the files are ready for testing. You can create new images from
the files available in the directory. You will want to check these files in
to your working branch before testing.

## Build and test the images

Build the images with the following command:

```
make build
make -f Makefile.inc build
```

This will run an image build against the generated cekit files and store
the image in the registry associated with your docker installation
(usually localhost).

The images are now ready for testing.
