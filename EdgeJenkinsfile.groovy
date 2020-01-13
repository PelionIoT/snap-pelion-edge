#!/usr/bin/env groovy
@Library('edge-ci') _

/**
Jenkinsfile for https://edge-jenkins.isgtesting.com/
*/

// Pod template documentation: https://github.com/jenkinsci/kubernetes-plugin#pod-and-container-template-configuration
podTemplate(yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: edge-snap-build-pod
spec:
  containers:
  - name: edge-snap-builder
    image: 853142832404.dkr.ecr.eu-west-1.amazonaws.com/edge/build/snap
    command: ['bash']
    tty: true
    alwaysPullImage: true
"""
) {

    node(POD_LABEL) {
        stage('Build') {
            // In here execution is in jnlp docker inside pod
            container('edge-snap-builder') {

                // Fetch repository
                checkout scm

                // Fetch cloud dev credentials
                writeFile(file: "mbed_cloud_dev_credentials.c", text: libraryResource("configs/intlab/mbed_cloud_dev_credentials.c"))

                // Approach copied from https://github.com/armPelionEdge/snap-pelion-edge/blob/dev/Jenkinsfile
                credentials.runWithSshCredentials() {
                    sh '''
                        git config --global user.email "mbed-edge-ci@arm.com"
                        git config --global user.name "mbed-edge-ci"

                        snapcraft --version
                        sudo apt-get update
                        snapcraft
                        ./scripts/install_check.sh prime/
                        '''
                }
                archiveArtifacts artifacts: 'pelion-edge_*.snap', fingerprint: true
            } // container
        } // stage
    } // node
} // Pod template
