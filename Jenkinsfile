pipeline {
    agent {
        dockerfile {
            args '-v jenkins-data:/root'
            label 'master'
        }
    }
    environment {
        MBED_CLOUD_DEV_CREDENTIALS_C = credentials('${mbed-cloud-dev-credentials-c}')
    }
    stages {
        stage('Build') {
            steps {
                sh '''
                    snapcraft --version
                    apt-get install -y git build-essential cmake
                    rm -rf snap-pelion-edge
                    git clone git@github.com:armpelionedge/snap-pelion-edge.git -b ${BRANCH}
                    cd snap-pelion-edge
                    cp "${MBED_CLOUD_DEV_CREDENTIALS_C}" mbed_cloud_dev_credentials.c
                    snapcraft
                    '''
            }
        }
    }
    post {
        success {
            archiveArtifacts artifacts: 'snap-pelion-edge/pelion-edge_*.snap', fingerprint: true
        }
    }
}
