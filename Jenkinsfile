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
                       -backend-config="bucket=${TF_STATE_BUCKET}" \\
                       -backend-config="key=${K8_TF_STATE_KEY}" \\
                       -backend-config="region=${AWS_DEFAULT_REGION}"'''
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
                    sh '''
                    my_ip=$(curl -s http://checkip.amazonaws.com)
                    cat <<EOF > terraform.tfvars
my_public_ip = "${my_ip}"
ssh_public_key = "${SSH_PUBLIC_KEY}"
aws_region = "${AWS_DEFAULT_REGION}"
aws_availability_zone = "${AWS_DEFAULT_AVAILABILITY_ZONE}"
state_bucket_name = "${TF_STATE_BUCKET}"
EOF
                    terraform plan -out=tfplan -var-file=terraform.tfvars
                    rm terraform.tfvars
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
                    sh '''
                    my_ip=$(curl -s http://checkip.amazonaws.com)
                    cat <<EOF > terraform.tfvars
my_public_ip = "${my_ip}"
ssh_public_key = "${SSH_PUBLIC_KEY}"
aws_region = "${AWS_DEFAULT_REGION}"
aws_availability_zone = "${AWS_DEFAULT_AVAILABILITY_ZONE}"
state_bucket_name = "${TF_STATE_BUCKET}"
EOF
                    terraform apply -auto-approve -var-file=terraform.tfvars tfplan
                    rm terraform.tfvars'''
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
                    sh '''
                    my_ip=$(curl -s http://checkip.amazonaws.com)
                    cat <<EOF > terraform.tfvars
my_public_ip = "${my_ip}"
ssh_public_key = "${SSH_PUBLIC_KEY}"
aws_region = "${AWS_DEFAULT_REGION}"
aws_availability_zone = "${AWS_DEFAULT_AVAILABILITY_ZONE}"
state_bucket_name = "${TF_STATE_BUCKET}"
EOF
                    terraform destroy -auto-approve -var-file=terraform.tfvars
                    rm terraform.tfvars
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