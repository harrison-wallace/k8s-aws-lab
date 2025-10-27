# k8s-aws-lab
A small automated k8s aws lab for learning and exam prep 

The idea is to create 3 ec2 instances 1 controlplane and 2 worker nodes which get created and configured via terraform and shell scipts

ssh access to control plane then it has access to the workers

## Required Variables in Jenkins:

```sh
AWS_DEFAULT_REGION='us-east-1'
TF_STATE_BUCKET='my-bucket'
K8_TF_STATE_KEY='k8s-aws-lab/terraform.tfstate'
```

## Required Credentials:

- AWS Credentials (type: AWS Credentials)
- SSH_PUBLIC_KEY (type: Secret Text)


## Kubernetes Setup:

- Kubeadm to initialize cluster 
- Calico network plugin (Supports Network Policies)
- Join cluster command outputted to `~/join-command.txt` on Control Plane node
 - SSH to Worker nodes and run command manually after cluster set up


## Troubleshooting:

The bootstrap scripts log output to these locations:

- `control-plane-bootstrap.sh` > `/var/log/control-plane-bootstrap.log`
- `worker-node-bootstrap.sh` > `/var/log/worker-node-bootstrap.log`
