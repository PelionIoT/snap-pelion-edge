pipeline {
    agent {
        docker {
            image 'snapcore/snapcraft:stable'
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
                    cp "${MBED_CLOUD_DEV_CREDENTIALS_C}" mbed_cloud_dev_credentials.c
                    apt-get update
                    snapcraft
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
