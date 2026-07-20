pipeline {
    agent any

    environment {
        // Securely pull infrastructure secrets from Jenkins Credentials Store
        // Using 'credentials()' automatically masks these values in build logs!
        AWS_REGION     = credentials('aws-region-secret')
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

                       docker build -t $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG .

                       docker tag $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPO:latest

                       docker push $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG
                       docker push $ECR_REGISTRY/$ECR_REPO:latest
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
                            # 1. Authenticate EC2 Docker with AWS ECR
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                            
                            # 2. Pull the latest image
                            docker pull $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG
                            
                            # 3. Stop and remove the old container if it exists
                            docker stop $CONTAINER_NAME || true
                            docker rm $CONTAINER_NAME || true
                            
                            # 4. Start the new container in detached mode
                            docker run -d --name $CONTAINER_NAME --restart always -p $PORT_MAPPING $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG
                            
                            # 5. Clean up unused Docker images on the server
                            docker image prune -f
                        "
                    '''
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
