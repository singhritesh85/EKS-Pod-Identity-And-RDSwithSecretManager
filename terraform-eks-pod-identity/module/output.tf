output "rds_endpoint" {
  description = "Endpoint of the RDS"
  value = aws_db_instance.dbinstance1.endpoint
}

output "EC2_Instance_Private_IP_Address" {
  description = "Private IP Address of the EC2 Instance"
  value = aws_instance.ec2.private_ip
}

output "eks_cluster_id" {
  description = "Name of the EKS cluster created"
  value       = aws_eks_cluster.eksdemo.id
}

output "eks_cluster_arn" {
  description = "The ARN (Amazon Resource Name) of the cluster"
  value       = aws_eks_cluster.eksdemo.arn
}
