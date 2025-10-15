pipeline {
    agent any

    environment {
        AWS_REGION      = 'ap-south-1'
        PROJECT_NAME    = 'devops-project'
        AWS_CREDENTIALS = credentials('aws-creds-id')
        ECR_ACCOUNT     = '775826428475'
        ECR_REGION      = "${env.AWS_REGION}"
        KUBE_NAMESPACE  = 'backend'
    }

    stages {

        // ------------------------------
        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds-id']]) {
                    sh """
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                    """
                }
            }
        }

        // ------------------------------
        stage('Configure Kubeconfig') {
            steps {
                sh """
                aws eks --region ${AWS_REGION} update-kubeconfig --name $(terraform output -raw eks_cluster_name)
                kubectl get nodes
                """
            }
        }

        // ------------------------------
        stage('Build & Push Docker Images') {
            steps {
                script {
                    def services = ['auth','product','cart','order','payment','email']
                    for (service in services) {
                        sh """
                        cd ${service}
                        docker build -t ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:latest .
                        aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com
                        docker push ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${service}:latest
                        """
                    }
                }
            }
        }

        // ------------------------------
        stage('Deploy Kubernetes Resources') {
            steps {
                sh """
                kubectl apply -f k8s/namespace/
                kubectl apply -f k8s/config/
                kubectl apply -f k8s/secrets/
                kubectl apply -f k8s/deployments/
                kubectl apply -f k8s/services/
                kubectl apply -f k8s/hpa/
                kubectl apply -f k8s/ingress/
                """
            }
        }

        // ------------------------------
        stage('Update ConfigMap & Restart Deployments') {
            steps {
                script {
                    // Fetch dynamic DB endpoint from Terraform
                    def db_host = sh(script: "terraform output -raw db_endpoint", returnStdout: true).trim()

                    // Wait for Ingress to create ALB, fetch its DNS
                    def alb_dns = sh(script: "kubectl get ingress backend-ingress -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'", returnStdout: true).trim()

                    echo "RDS Endpoint: ${db_host}"
                    echo "ALB DNS: ${alb_dns}"

                    // Update ConfigMap placeholders
                    sh """
                    sed -i 's|REPLACE_DB_ENDPOINT|${db_host}|' k8s/config/backend-configmap.yaml
                    sed -i 's|REPLACE_ORDERS_ALB_DNS|http://${alb_dns}|' k8s/config/backend-configmap.yaml
                    kubectl apply -f k8s/config/backend-configmap.yaml -n ${KUBE_NAMESPACE}
                    """

                    // Restart deployments to pick up new config
                    def services = ['auth','product','cart','order','payment','email']
                    for (service in services) {
                        sh "kubectl rollout restart deployment ${service} -n ${KUBE_NAMESPACE}"
                    }
                }
            }
        }

        // ------------------------------
        stage('Build & Deploy Frontend to S3') {
            steps {
                script {
                    // Fetch ALB DNS from backend ingress
                    def alb_dns = sh(script: "kubectl get ingress backend-ingress -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'", returnStdout: true).trim()
                    echo "ALB DNS: ${alb_dns}"

                    // Update frontend .env with ALB DNS only
                    sh """
                    cd frontend
                    sed -i 's|REACT_APP_API_URL=.*|REACT_APP_API_URL=http://${alb_dns}|' .env
                    npm install
                    npm run build
                    aws s3 sync build/ s3://devops-project-frontend-rajesh --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment to EKS Fargate and frontend S3 complete!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}