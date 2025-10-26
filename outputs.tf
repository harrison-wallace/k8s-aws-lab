# Output the public IPs of the instances
output "control_plane_public_ip" {
  value = aws_instance.control_plane.public_ip
  description = "🌎- Public IP address of the control plane instance"
}

output "worker_private_ips" {
  value = [for instance in aws_instance.worker : instance.private_ip]
  description = "🏢- Private IP addresses of the worker instances"
}

# Commands to start and stop EC2 instances

output "stop_ec2_instances_command" {
  value = "aws ec2 stop-instances --instance-ids ${aws_instance.control_plane.id} ${join(" ", aws_instance.worker.*.id)} --region ${var.aws_region}"
  description = "🛑- Command to stop EC2 instances"
}

output "start_ec2_instances_command" {
  value = "aws ec2 start-instances --instance-ids ${aws_instance.control_plane.id} ${join(" ", aws_instance.worker.*.id)} --region ${var.aws_region}"
  description = "▶️- Command to start EC2 instances"
}

# Output SSH Command for Control Plane

output "ssh_command_control_plane" {
  value = "ssh -i <path_to_private_key> ubuntu@${aws_instance.control_plane.public_ip} -o StrictHostKeyChecking=no"
  description = "🔐- SSH command to access the control plane instance "
}
