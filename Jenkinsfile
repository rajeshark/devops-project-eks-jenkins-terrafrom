pipeline {
    agent any
    
    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'  // Replace with your actual AWS Account ID
    }
    
    stages {
        // STAGE 1: Terraform Infrastructure
        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    echo "=== CREATING AWS INFRASTRUCTURE ==="
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }
        
        // STAGE 2: Get Terraform Outputs
        stage('Get Terraform Outputs') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        env.DB_HOST = sh(script: 'terraform output -raw db_endpoint', returnStdout: true).trim()
                        env.ALB_DNS = sh(script: 'terraform output -raw alb_dns_name', returnStdout: true).trim()
                        env.EKS_CLUSTER = sh(script: 'terraform output -raw eks_cluster_name', returnStdout: true).trim()
                        
                        echo "=== TERRAFORM OUTPUTS ==="
                        echo "DB_HOST: ${env.DB_HOST}"
                        echo "ALB_DNS: ${env.ALB_DNS}"
                        echo "EKS_CLUSTER: ${env.EKS_CLUSTER}"
                    }
                }
            }
        }
        
        // STAGE 3: Configure EKS Access
        stage('Configure EKS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                    echo "=== CONFIGURING EKS ACCESS ==="
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${env.EKS_CLUSTER}
                    echo "EKS Cluster connected:"
                    kubectl get nodes
                    """
                }
            }
        }
        
        // STAGE 4: Install ALB Controller
        stage('Install ALB Controller') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                    echo "=== INSTALLING AWS LOAD BALANCER CONTROLLER ==="
                    
                    # Download IAM policy
                    curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
                    
                    # Create IAM policy (skip if exists)
                    aws iam create-policy \\
                        --policy-name AWSLoadBalancerControllerIAMPolicy \\
                        --policy-document file://iam_policy.json \\
                        --region ${AWS_REGION} || echo "Policy may already exist"
                    
                    # Install ALB Controller using Helm
                    helm repo add eks https://aws.github.io/eks-charts
                    helm repo update
                    
                    # Install ALB Controller
                    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \\
                        -n kube-system \\
                        --set clusterName=${env.EKS_CLUSTER} \\
                        --set serviceAccount.create=false \\
                        --set serviceAccount.name=aws-load-balancer-controller \\
                        --set region=${AWS_REGION} \\
                        --wait
                    
                    # Wait for controller to be ready
                    echo "Waiting for ALB Controller to be ready..."
                    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=300s
                    
                    echo "AWS Load Balancer Controller installed successfully!"
                    """
                }
            }
        }
        
        // STAGE 5: Create TargetGroupBinding Files
        stage('Create TargetGroupBinding') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "=== CREATING TARGETGROUP BINDING FILES ==="
                        
                        // Get Target Group ARNs from AWS
                        def tgAuth = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-auth --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        def tgProduct = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-product --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        def tgCart = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-cart --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        def tgOrder = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-order --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        def tgPayment = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-payment --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        def tgEmail = sh(
                            script: "aws elbv2 describe-target-groups --names devops-project-tg-email --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                        
                        echo "Target Group ARNs:"
                        echo "Auth: ${tgAuth}"
                        echo "Product: ${tgProduct}"
                        echo "Cart: ${tgCart}"
                        echo "Order: ${tgOrder}"
                        echo "Payment: ${tgPayment}"
                        echo "Email: ${tgEmail}"
                        
                        // Create TargetGroupBinding YAML file dynamically
                        def targetGroupBindingYaml = """
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-auth
  namespace: backend
spec:
  serviceRef:
    name: auth-service
    port: 5005
  targetGroupARN: ${tgAuth}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-product
  namespace: backend
spec:
  serviceRef:
    name: product-service
    port: 5001
  targetGroupARN: ${tgProduct}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-cart
  namespace: backend
spec:
  serviceRef:
    name: cart-service
    port: 5002
  targetGroupARN: ${tgCart}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-order
  namespace: backend
spec:
  serviceRef:
    name: order-service
    port: 5003
  targetGroupARN: ${tgOrder}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-payment
  namespace: backend
spec:
  serviceRef:
    name: payment-service
    port: 5004
  targetGroupARN: ${tgPayment}
---
apiVersion: elbv2.k8s.aws/v1beta1
kind: TargetGroupBinding
metadata:
  name: tg-binding-email
  namespace: backend
spec:
  serviceRef:
    name: email-service
    port: 5006
  targetGroupARN: ${tgEmail}
"""
                        
                        // Write to file
                        writeFile file: 'k8s/alb-controller/targetgroup-binding.yaml', text: targetGroupBindingYaml
                        
                        echo "TargetGroupBinding file created successfully!"
                    }
                }
            }
        }
        
        // STAGE 6: Build Docker Images
        stage('Build Docker Images') {
            steps {
                script {
                    echo "=== BUILDING DOCKER IMAGES ==="
                    sh '''
                    docker build -t 1234-auth ./auth
                    docker build -t 1234-product ./product
                    docker build -t 1234-cart ./cart
                    docker build -t 1234-order ./order
                    docker build -t 1234-payment ./payment
                    docker build -t 1234-email ./email
                    '''
                }
            }
        }
        
        // STAGE 7: Push to ECR
        stage('Push to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        echo "=== PUSHING TO ECR ==="
                        // Login to ECR
                        sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        """
                        
                        // Tag and push all images
                        sh '''
                        docker tag 1234-auth:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-auth:latest
                        docker tag 1234-product:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-product:latest
                        docker tag 1234-cart:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-cart:latest
                        docker tag 1234-order:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-order:latest
                        docker tag 1234-payment:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-payment:latest
                        docker tag 1234-email:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-email:latest

                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-auth:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-product:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-cart:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-order:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-payment:latest
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-email:latest
                        '''
                    }
                }
            }
        }
        
        // STAGE 8: Update K8s Manifests
        stage('Update K8s Manifests') {
            steps {
                sh """
                echo "=== UPDATING K8S MANIFESTS ==="
                
                # Update image names in deployment files
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-auth|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-auth|g' {} \\;
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-product|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-product|g' {} \\;
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-cart|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-cart|g' {} \\;
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-order|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-order|g' {} \\;
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-payment|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-payment|g' {} \\;
                find k8s/deployment -name "*.yaml" -exec sed -i 's|1234-email|${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/1234-email|g' {} \\;
                
                # Update DB_HOST in all deployment files
                find k8s/deployment -name "*.yaml" -exec sed -i 's/YOUR_RDS_ENDPOINT/${env.DB_HOST}/g' {} \\;
                
                # Update ALB DNS in payment service
                sed -i 's|http://YOUR_ALB_DNS|http://${env.ALB_DNS}|g' k8s/deployment/payment.yaml
                
                echo "Manifests updated successfully!"
                """
            }
        }
        
        // STAGE 9: Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                echo "=== DEPLOYING TO KUBERNETES ==="
                
                # Make deploy script executable and run it
                chmod +x k8s/deploy-all.sh
                ./k8s/deploy-all.sh
                """
            }
        }
        
        // STAGE 10: Build and Deploy Frontend
        stage('Deploy Frontend') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh """
                    echo "=== BUILDING AND DEPLOYING FRONTEND ==="
                    
                    # STEP 1: Update frontend .env with ALB DNS BEFORE building
                    echo "Updating frontend .env with ALB DNS: ${env.ALB_DNS}"
                    cd frontend
                    sed -i 's|YOUR_ALB_DNS_NAME|${env.ALB_DNS}|g' .env
                    
                    # Verify the change
                    echo "Updated .env file:"
                    cat .env
                    
                    # STEP 2: Now build React app with the updated API URL
                    echo "Building React frontend with updated API URL..."
                    npm install
                    npm run build
                    
                    # STEP 3: Upload to S3
                    echo "Uploading to S3 bucket: devops-project-frontend"
                    aws s3 sync ./build/ s3://devops-project-frontend/ --delete
                    
                    echo "Frontend successfully deployed to S3!"
                    """
                }
            }
        }
        
        // STAGE 11: Verify Deployment
        stage('Verify Deployment') {
            steps {
                sh """
                echo "=== FINAL DEPLOYMENT VERIFICATION ==="
                sleep 30  # Wait for pods to start
                
                echo "1. Backend Pods Status:"
                kubectl get pods -n backend -o wide
                
                echo ""
                echo "2. Services:"
                kubectl get services -n backend
                
                echo ""
                echo "3. HPA Status:"
                kubectl get hpa -n backend
                
                echo ""
                echo "4. TargetGroupBindings:"
                kubectl get targetgroupbindings -n backend
                
                echo ""
                echo "🎉 === DEPLOYMENT COMPLETE ==="
                echo ""
                echo "📱 FRONTEND URL:"
                echo "   http://devops-project-frontend.s3-website.ap-south-1.amazonaws.com"
                echo ""
                echo "🔧 BACKEND API URL:"
                echo "   http://${env.ALB_DNS}"
                echo ""
                echo "📋 API ENDPOINTS:"
                echo "   Auth:     http://${env.ALB_DNS}/api/auth"
                echo "   Products: http://${env.ALB_DNS}/api/products"
                echo "   Cart:     http://${env.ALB_DNS}/api/cart"
                echo "   Orders:   http://${env.ALB_DNS}/api/orders"
                echo "   Payments: http://${env.ALB_DNS}/api/payments"
                echo "   Email:    http://${env.ALB_DNS}/api/email"
                echo ""
                echo "🗄️ DATABASE:"
                echo "   Endpoint: ${env.DB_HOST}"
                echo ""
                echo "🚀 Your full-stack application is now LIVE!"
                """
            }
        }
    }
    
    post {
        always {
            echo '=== JENKINS PIPELINE EXECUTION COMPLETE ==='
        }
        success {
            echo '✅ SUCCESS! Full-stack application deployed successfully!'
            echo '🌐 Frontend: http://devops-project-frontend.s3-website.ap-south-1.amazonaws.com'
            echo '🔧 Backend: http://${env.ALB_DNS}'
        }
        failure {
            echo '❌ DEPLOYMENT FAILED! Check logs above for errors.'
        }
    }
}