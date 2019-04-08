# Functional testing

This repository contains a set of end-to-end functional tests. These tests
will create the images, deploy them, and run a few basic connectivity and
application suites.

These tests will run automatically on all proposed changes to the project
repository, but it is often useful to run them locally to diagnose changes or
hunt for bugs. Although the tests are automated, running them locally requires
a very specific setup. These instructions will guide you through the process.

## Prerequisites

* Access to an OpenShift cluster available. You will need to have basic access
  to a cluster with the ability to create new projects and objects within
  those projects. We recommend using a local deployment methodology for these
  tests, you can find more information about deploying OpenShift in
  [this upstream documentation](https://docs.okd.io/latest/getting_started/administrators.html).
* Access to the `docker` tooling on the OpenShift cluster instance. The test
  tooling will create and push the images to a local container registry using
  `docker`. The test suite will need to build and push images, ensure that
  you have this access.
* GNU `make` available. The tests are run through the `Makefile`, you will
  need this command to start the entire process.
* Go language tooling available. As the tests will attempt to build certain
  Go specific applications, you will need to have the Go tooling installed on
  the machine where the tests will run.

## Procedure

1. Download the source code. You will need to clone this repository onto the
   host where the tests will run.
1. Login to OpenShift and create a new project. The test scripts will attempt
   to determine your project namespace, occasionally it is possible to have a
   login with no associated project. To avoid errors, create a project with
   any name or switch to a previously used project, the test suite will create
   a new project for its work.
1. Start the tests. Change directory to the root of the repository clone and
   run the make command, this will start the tests and you will see the output
   in your terminal. This command will run all the tests:
   ```
   make test-e2e
   ```

## Additional resources

* [Makefile](/Makefile). This is where all the action starts, see the entry
  for the `test-e2e` target.
* [test/run.sh](/test/run.sh). This script file is the primary entrypoint for
  all the test suites, you should examine this file to understand how the
  tests are structured and executed.
