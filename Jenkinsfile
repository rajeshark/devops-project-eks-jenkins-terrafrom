pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ACCOUNT_ID = credentials('aws-account-id')   // AWS account ID stored in Jenkins credentials
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id') // AWS Access Key stored in Jenkins
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key') // AWS Secret stored in Jenkins
        PROJECT_NAME = 'quickcart'
        FRONTEND_BUCKET_NAME = 'devops-project-frontend'
    }

    stages {
        stage('Pull code from GitHub') {
            steps {
                git branch: 'master', url: 'https://github.com/rajeshark/devops-project.git'
            }
        }

        stage('Terraform Init, Plan & Apply') {
            steps {
                echo "Initializing and applying Terraform..."
                dir('terraform') {      // Terraform files folder
                    sh 'terraform init'
                    sh 'terraform plan'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Build & Push Docker Images to ECR') {
            steps {
                echo "Building and pushing Docker images to ECR..."
                dir('.') {
                    sh './build_push.sh'
                }
            }
        }

        stage('Update ConfigMaps') {
            steps {
                echo "Updating Kubernetes ConfigMaps with Terraform outputs..."
                dir('terraform') {
                    script {
                        DB_HOST = sh(script: "terraform output -raw db_endpoint", returnStdout: true).trim()
                        ALB_DNS = sh(script: "terraform output -raw alb_dns_name", returnStdout: true).trim()
                    }
                }

                dir('k8s') {
                    script {
                        def services = ["auth", "product", "cart", "order", "payment", "email"]
                        for (s in services) {
                            sh """
                                sed -i 's|<RDS_ENDPOINT>|$DB_HOST|g' ${s}/configmap.yaml
                                sed -i 's|<ALB_DNS_NAME>|$ALB_DNS|g' ${s}/configmap.yaml
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy Kubernetes Manifests') {
            steps {
                echo "Applying Kubernetes deployments..."
                dir('k8s') {
                    sh 'kubectl apply -f .'
                }
            }
        }

        stage('Verify Kubernetes Deployment') {
            steps {
                echo "Verifying deployment..."
                sh 'kubectl get pods -n backend'
                sh 'kubectl get services -n backend'
            }
        }

        stage('Update Frontend .env') {
            steps {
                echo "Replacing ALB DNS in frontend .env..."
                dir('frontend') {
                    sh """
                        sed -i 's|<ALB_DNS_NAME>|$ALB_DNS|g' .env
                    """
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('Deploy Frontend to S3') {
            steps {
                dir('frontend') {
                    // Delete everything except 'products' folder
                    sh """
                        aws s3 ls s3://$FRONTEND_BUCKET_NAME/ | awk '{print \$4}' | grep -v '^products/' | while read file; do
                            aws s3 rm s3://$FRONTEND_BUCKET_NAME/\$file --recursive
                        done
                    """
                    // Sync new build to S3
                    sh """
                        aws s3 sync build/ s3://$FRONTEND_BUCKET_NAME --exact-timestamps
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}