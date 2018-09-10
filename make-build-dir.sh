#!/bin/bash

# Regenerate the build directory based on image.*.yaml
make clean-target
make clean-context
make -f Makefile.inc clean-context

make context
make -f Makefile.inc context

make zero-tarballs
make -f Makefile.inc zero-tarballs

# Add any changes for a commit
git add openshift-spark-build
git add openshift-spark-build-py36
git add openshift-spark-build-inc
git add openshift-spark-build-inc-py36
