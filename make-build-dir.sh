#!/bin/bash

# Regenerate the build directory based on image.*.yaml
make clean-context
make context
make zero-tarballs

# Add any changes for a commit
git add openshift-spark-build
git add openshift-spark-build-py36
