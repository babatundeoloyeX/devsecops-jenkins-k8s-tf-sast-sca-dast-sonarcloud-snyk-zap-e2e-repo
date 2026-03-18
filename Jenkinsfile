pipeline {
    agent any

    tools {
        maven 'Maven_3_8_4'
    }

    environment {
        PATH = "/usr/local/bin:/usr/bin:${env.PATH}"
        DOCKER_IMAGE = "asg"
    }

    stages {

        stage('Compile and Run Sonar Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=webappdevsecproject \
                    -Dsonar.organization=webappdevsecproject \
                    -Dsonar.host.url=https://sonarcloud.io \
                    -Dsonar.token=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Run SCA Analysis Using Snyk') {
            steps {
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    sh '''
                    snyk auth $SNYK_TOKEN
                    snyk test || true
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def app = docker.build("${DOCKER_IMAGE}")
                }
            }
        }

        stage('Push Docker Image to AWS ECR') {
            steps {
                script {
                    docker.withRegistry(
                        'https://891377015455.dkr.ecr.ap-southeast-2.amazonaws.com',
                        'ecr:ap-southeast-2:aws-credentials'
                    ) {
                        docker.image("${DOCKER_IMAGE}").push("latest")
                    }
                }
            }
        }

        stage('Kubernetes Deployment of ASG Bugg Web Application') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    sh 'kubectl delete all --all -n devsecops'
                    sh 'kubectl apply -f deployment.yaml --namespace=devsecops'
                }
            }
        }

        stage('wait_for_testing') {
            steps {
                sh 'pwd; sleep 180; echo "Application Has been deployed on K8S"'
            }
        }

        stage('RunDASTUsingZAP') {
          steps {
            withKubeConfig([credentialsId: 'kubelogin']) {
              sh '''
              TARGET=$(kubectl get services/asgbuggy --namespace=devsecops -o json | jq -r ".status.loadBalancer.ingress[0].hostname")

              docker run --rm -u root \
              -v $(pwd):/zap/wrk/:rw \
              zaproxy/zap-stable \
              zap-baseline.py -t http://$TARGET -r zap_report.html || true
              '''
              archiveArtifacts artifacts: 'zap_report.html'
      }
   }
}

    }
}
