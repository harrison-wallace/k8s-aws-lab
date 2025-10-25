pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
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
               sh 'terraform init -backend-config="bucket=${TF_STATE_BUCKET}" -backend-config="region=${AWS_DEFAULT_REGION}"'
           }
          }
      }

     stage('Terraform Plan') {
          steps {
           withCredentials([[
               $class: 'AmazonWebServicesCredentialsBinding', 
               credentialsId: 'aws-credentials',
               accessKeyVariable: 'AWS_ACCESS_KEY_ID',
               secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
           ]]) {
               sh 'terraform plan -out=tfplan'
           }
          }
      }
      stage('Terraform Apply') {
          steps {
           withCredentials([[
               $class: 'AmazonWebServicesCredentialsBinding', 
               credentialsId: 'aws-credentials',
               accessKeyVariable: 'AWS_ACCESS_KEY_ID',
               secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
           ]]) {
               sh 'terraform apply -auto-approve tfplan'
           }
          }
      }

      post {
          always {
              cleanWs()
          }
      }
}