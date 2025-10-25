# k8s-aws-lab
A small automated k8s aws lab for learning and exam prep 

The idea is to create 3 ec2 instances 1 controlplane and 2 worker nodes which get created and configured via terraform and shell scipts

ssh access to control plane then it has access to the workers


## Required Variables in Jenkins:

```sh
AWS_DEFAULT_REGION='us-east-1'
TF_STATE_BUCKET='my-bucket'
TF_STATE_KEY='k8s-aws-lab/'
```

## Required Credentials:

- AWS Credentials (type: AWS Credentials)
- SSH_PUBLIC_KEY (type: Secret Text)



