#! /bin/bash

# Check for at least one argument
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
fi

ACTION=$1

# Define instance names
CONTROL_PLANE_INSTANCE="k8s-control-plane"
WORKER_INSTANCE_1="k8s-worker-1"
WORKER_INSTANCE_2="k8s-worker-2"

CONTROL_PLANE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$CONTROL_PLANE_INSTANCE" --query "Reservations[*].Instances[*].InstanceId" --output text)
WORKER_ID_1=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$WORKER_INSTANCE_1" --query "Reservations[*].Instances[*].InstanceId" --output text)
WORKER_ID_2=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$WORKER_INSTANCE_2" --query "Reservations[*].Instances[*].InstanceId" --output text)


# Perform action based on user input
case $ACTION in
    start)
        aws ec2 start-instances --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        echo "Starting instances..."
        if [ $? -ne 0 ] ; then
            echo "Failed to start instances. Please check your AWS CLI configuration and instance states."
            exit 1
        fi
        echo "Waiting for instances to be in 'running' state..."
        aws ec2 wait instance-running --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        CONTROL_PLANE_IP=$(aws ec2 describe-instances --instance-ids $CONTROL_PLANE_ID --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
        echo "Control Plane Public IP: $CONTROL_PLANE_IP"
        echo "Instances are now running."
        ;;
    stop)
        aws ec2 stop-instances --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        echo "Stopping instances..."
        if [ $? -ne 0 ] ; then
            echo "Failed to stop instances. Please check your AWS CLI configuration and instance states."
            exit 1
        fi
        echo "Waiting for instances to be in 'stopped' state..."
        aws ec2 wait instance-stopped --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        echo "Instances are now stopped."
        ;;
    restart)
        aws ec2 reboot-instances --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        echo "Restarting instances..."
        if [ $? -ne 0 ] ; then
            echo "Failed to restart instances. Please check your AWS CLI configuration and instance states."
            exit 1
        fi
        echo "Waiting for instances to be in 'running' state..."
        aws ec2 wait instance-running --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2
        echo "Instances are now running."
        ;;
    status)
        aws ec2 describe-instances --instance-ids $CONTROL_PLANE_ID $WORKER_ID_1 $WORKER_ID_2 --query "Reservations[*].Instances[*].[InstanceId,State.Name]" --output table
        ;;
    *)
        echo "Invalid action. Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac