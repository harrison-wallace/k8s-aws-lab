pipeline {
    agent any

    parameters {
        booleanParam(name: 'DESTROY_INFRA', defaultValue: false, description: 'Set to true to destroy the infrastructure after deployment.')
    }

    environment {
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''terraform init \\
                       -backend-config='bucket="${TF_STATE_BUCKET}"' \\
                       -backend-config='key="${TF_STATE_KEY}"' \\
                       -backend-config='region="${AWS_DEFAULT_REGION}"'
                       '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.DESTROY_INFRA == false }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ], string(credentialsId: 'SSH_PUBLIC_KEY', variable: 'SSH_PUBLIC_KEY')]) {
                    sh '''terraform plan -out=tfplan \\
                       -var='my_public_ip="$(curl -s http://checkip.amazonaws.com)"' \\
                       -var='ssh_public_key="${SSH_PUBLIC_KEY}"' \\
                       -var='aws_region="${AWS_DEFAULT_REGION}"' \\
                       -var='aws_availability_zone="${AWS_DEFAULT_AVAILABILITY_ZONE}"' \\
                       -var='state_bucket_name="${TF_STATE_BUCKET}"' \\
                       '''
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.DESTROY_INFRA == false }
                branch 'main'
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ], string(credentialsId: 'SSH_PUBLIC_KEY', variable: 'SSH_PUBLIC_KEY')]) {
                    sh '''terraform apply -auto-approve \\
                       -var='my_public_ip="$(curl -s http://checkip.amazonaws.com)"' \\
                       -var='ssh_public_key="${SSH_PUBLIC_KEY}"' \\
                       -var='aws_region="${AWS_DEFAULT_REGION}"' \\
                       -var='aws_availability_zone="${AWS_DEFAULT_AVAILABILITY_ZONE}"' \\
                       -var='state_bucket_name="${TF_STATE_BUCKET}"' \\
                       tfplan'''
                }
            }
        }
        stage('Terraform Destroy') {
            when {
                expression { params.DESTROY_INFRA == true }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ], string(credentialsId: 'SSH_PUBLIC_KEY', variable: 'SSH_PUBLIC_KEY')]) {
                    sh '''terraform destroy -auto-approve \\
                       -var='my_public_ip="$(curl -s http://checkip.amazonaws.com)"' \\
                       -var='ssh_public_key="${SSH_PUBLIC_KEY}"' \\
                       -var='aws_region="${AWS_DEFAULT_REGION}"' \\
                       -var='aws_availability_zone="${AWS_DEFAULT_AVAILABILITY_ZONE}"' \\
                       -var='state_bucket_name="${TF_STATE_BUCKET}"' 
                       '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}