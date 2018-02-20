#!/usr/bin/env groovy

// Used Jenkins plugins:
// * Pipeline GitHub Notify Step Plugin
// * Disable GitHub Multibranch Status Plugin
//
// $OCP_HOSTNAME -- hostname of running Openshift cluster
// $OCP_USER     -- Openshift user
// $OCP_PASSWORD -- Openshift user's password

node {
	withEnv(["KUBECONFIG=$WORKSPACE/client/kubeconfig", "PATH+OC_PATH=$WORKSPACE/client"]) {

		// generate build url
		def buildUrl = sh(script: 'curl https://url.corp.redhat.com/new?$BUILD_URL', returnStdout: true)

		stage('Test') {

			try {
				githubNotify(context: 'jenkins-ci/openshift-spark', description: 'This change is being tested', status: 'PENDING', targetUrl: buildUrl)
			} catch (err) {
				echo("Wasn't able to notify Github: ${err}")
			}

			try {
				// wipeout workspace
				deleteDir()

				dir('openshift-spark') {
					checkout scm
				}

				// download oc client
				dir('client') {
					sh('curl -LO https://github.com/openshift/origin/releases/download/v3.7.0/openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit.tar.gz')
					sh('curl -LO https://github.com/openshift/origin/releases/download/v3.7.0/openshift-origin-server-v3.7.0-7ed6862-linux-64bit.tar.gz')
					sh('tar -xzf openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit.tar.gz')
					sh('tar -xzf openshift-origin-server-v3.7.0-7ed6862-linux-64bit.tar.gz')
					sh('cp openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit/oc .')
					sh('cp openshift-origin-server-v3.7.0-7ed6862-linux-64bit/* .')
				}

				// login to openshift instance
				sh('oc login https://$OCP_HOSTNAME:8443 -u $OCP_USER -p $OCP_PASSWORD --insecure-skip-tls-verify=true')
				// let's start on a specific project, to prevent start on a random project which could be deleted in the meantime
				sh('oc project testsuite')

				// test
				dir('openshift-spark') {
					sh('make build | tee -a test.log && exit ${PIPESTATUS[0]}')
				}
			} catch (err) {
				try {
					githubNotify(context: 'jenkins-ci/openshift-spark', description: 'There are test failures', status: 'ERROR', targetUrl: buildUrl)
				} catch (errNotify) {
					echo("Wasn't able to notify Github: ${errNotify}")
				}
				throw err
			} finally {
				dir('openshift-spark') {
					archiveArtifacts(allowEmptyArchive: true, artifacts: 'test.log')
				}
			}

			try {
				githubNotify(context: 'jenkins-ci/openshift-spark', description: 'This change looks good', status: 'SUCCESS', targetUrl: buildUrl)
			} catch (err) {
				echo("Wasn't able to notify Github: ${err}")
			}
		}
	}
}
