pipeline {
    agent {
        dockerfile {
            label 'docker'
        }
    }
    environment {
        MBED_CLOUD_DEV_CREDENTIALS_C = credentials('${mbed-cloud-dev-credentials-c}')
        UPDATE_DEFAULT_RESOURCES_C = credentials('${update-default-resources-c}')
    }
    stages {
        stage('Setup') {
            steps {
                sh '''
                    snapcraft --version
                    mkdir -p ~/.ssh; chmod 0700 ~/.ssh
                    ssh-keyscan github.com >> ~/.ssh/known_hosts
                    git config --global user.email "jenkins@localhost"
                    git config --global user.name "Jenkins"
                    apt-get update
                '''
            }
        }
        stage('Build') {
            steps {
                sshagent(credentials: ['c9c1171e-fac3-4ec9-99cc-1f8a351e71ae']) {
                    sh '''
                    cp "${MBED_CLOUD_DEV_CREDENTIALS_C}" mbed_cloud_dev_credentials.c
                    cp "${UPDATE_DEFAULT_RESOURCES_C}" update_default_resources.c
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
