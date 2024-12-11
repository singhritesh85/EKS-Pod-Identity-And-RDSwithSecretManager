output "acr_ec2_private_ip_alb_dns" {
  description = "Details of the RDS Instance endpoint Created, EC2 Instances Private IPs and created EKS Cluster Name"
  value       = "${module.eks_cluster}"
}
