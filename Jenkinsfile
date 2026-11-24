pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'apply = Provision Infra & Push Image | destroy = Tear down Infra'
        )
    }

    environment {
        ARM_CLIENT_ID       = credentials('azure-client-id')
        ARM_CLIENT_SECRET   = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID       = credentials('azure-tenant-id')
        GITHUB_PAT          = credentials('github-pat')
        APP_NAME            = "ecommerce-frontend"
        IMAGE_TAG           = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh "terraform plan -out=tfplan ${params.ACTION == 'destroy' ? '-destroy' : ''}"
                }
            }
        }

        stage('Terraform Execute') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Build & Push Docker Image to ACR') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    dir('terraform') {
                        env.ACR_SERVER = sh(script: 'terraform output -raw acr_login_server', returnStdout: true).trim()
                    }
                    env.FULL_IMAGE = "${env.ACR_SERVER}/${env.APP_NAME}:${env.IMAGE_TAG}"
                }
                dir('app') {
                    sh '''
                        az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
                        az acr login --name $(echo $ACR_SERVER | cut -d'.' -f1)
                        docker build -t $FULL_IMAGE .
                        docker push $FULL_IMAGE
                    '''
                }
            }
        }

        stage('Update GitOps Manifest in GitHub') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh '''
                    git config user.email "jenkins@ecommerce-devops.local"
                    git config user.name "Jenkins CI"
                    sed -i "s|image: .*|image: ${FULL_IMAGE}|g" k8s/deployment.yaml
                    git add k8s/deployment.yaml
                    git commit -m "chore(gitops): update image to ${FULL_IMAGE} [skip ci]" || exit 0
                    git push https://${GITHUB_PAT}@://github.com HEAD:main
                '''
            }
        }
    }

    post {
        always {
            dir('terraform') {
                sh 'rm -f tfplan'
            }
        }
        success {
            echo "CI completed! ArgoCD will automatically sync ${env.FULL_IMAGE} to AKS."
        }
    }
}
