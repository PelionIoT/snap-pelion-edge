pipeline {
    agent {
        dockerfile {
            label 'master'
        }
    }
    environment {
        MBED_CLOUD_DEV_CREDENTIALS_C = credentials('${mbed-cloud-dev-credentials-c}')
    }
    stages {
        stage('Setup') {
            steps {
                sh '''
                    snapcraft --version
                    mkdir -p ~/.ssh; chmod 0700 ~/.ssh
                    ssh-keyscan github.com >> ~/.ssh/known_hosts
                    apt-get update
                '''
            }
        }
        stage('Build') {
            steps {
                sshagent(credentials: ['c9c1171e-fac3-4ec9-99cc-1f8a351e71ae']) {
                    sh '''
                    cp "${MBED_CLOUD_DEV_CREDENTIALS_C}" mbed_cloud_dev_credentials.c
                    snapcraft
                    '''
                }
            }
        }
        stage('Test') {
            steps {
                sh '''
                    ./scripts/install_check.sh prime/
                '''
            }
        }
    }
    post {
        success {
            archiveArtifacts artifacts: 'pelion-edge_*.snap', fingerprint: true
        }
    }
}
