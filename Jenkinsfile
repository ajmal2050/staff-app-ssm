pipeline {
    agent any

    environment {
        // Securely pull infrastructure secrets from Jenkins Credentials Store
        // Using 'credentials()' automatically masks these values in build logs!
        AWS_REGION     = credentials('aws-region-secret')
        TARGET_GROUP_ARN = credentials('aws-target-group-arn')   // ARN of your ALB target group
        ECR_REGISTRY   = credentials('aws-ecr-registry-url')
        ECR_REPO       = credentials('aws-ecr-repo-name')
        EC2_PRIVATE_IP = credentials('ec2-private-ip-secret')
        EC2_USER       = credentials('ec2-ssh-username')
        
        // Dynamic build tag
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        CONTAINER_NAME = 'my-running-app'
        PORT_MAPPING   = '80:8080'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('2. Build Docker Images') {
            steps {
                echo 'Building Docker images using Docker Compose...'
                script {
                    // FIXED: Using docker compose to read your backend/frontend folders automatically!
                    // And using triple single-quotes (''') for security.
                    sh '''
                        docker compose build
                    '''
                }
            }
        }

        stage('3. Push to AWS ECR') {
            steps {
                echo 'Authenticating and pushing image to AWS ECR...'
                // Scoped AWS credential binding for ECR push
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-ecr-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                       aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                       docker tag ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPO}:latest
                       docker push ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}
                       docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
                       
                      '''
                }
            }
        }

        stage('4. Deploy to Private EC2') {
            steps {
                echo 'Deploying to private EC2 instance...'
                // Scoped SSH agent binding for private key authentication
                sshagent(['ec2-private-ssh-key']) {
                    // FIXED: Changed """ to ''' and removed { } around variables!
                sh '''
        ssh -o StrictHostKeyChecking=no $EC2_USER@$EC2_PRIVATE_IP "
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY &&
            docker pull $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG &&
            docker stop $CONTAINER_NAME || true &&
            docker rm $CONTAINER_NAME || true &&
            docker run -d --name $CONTAINER_NAME --restart always -p $PORT_MAPPING $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG &&
            docker image prune -f
        "
    '''
                }
            }
        }

       stage('5. Register with Load Balancer') {
    steps {
        echo "Registering EC2 instance with Load Balancer..."
        sshagent(['your-ssh-credential-id']) {
            // Using triple double-quotes (""") allows Groovy to inject Jenkins env variables 
            // like ${EC2_USER} while we escape bash variables (\$) to run remotely.
            sh """
                ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_PRIVATE_IP} '
                    # 1. Fetch IMDSv2 token
                    TOKEN=\$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
                    
                    # 2. Fetch Instance ID using the token
                    INSTANCE_ID=\$(curl -H "X-aws-ec2-metadata-token: \$TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
                    
                    # 3. Register with ALB
                    aws elbv2 register-targets \\
                        --target-group-arn ${TARGET_GROUP_ARN} \\
                        --targets Id=\$INSTANCE_ID
                '
            """
        }
    }
}
     
    }

    post {
        success {
            echo '✅ Pipeline succeeded! Application deployed securely.'
        }
        failure {
            echo '❌ Pipeline failed. Please check the build logs above.'
        }
    }
}
