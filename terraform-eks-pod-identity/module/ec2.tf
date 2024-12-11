############################################################### EC2 Instance #####################################################################
# Security Group for EC2 Instance
resource "aws_security_group" "ec2" {
  name        = "EC2 Instance Security Group"
  description = "Security Group for EC2 Instance"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["10.10.0.0/16"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-instance-sg"
  }
}

resource "aws_instance" "ec2" {
  ami           = var.provide_ami
  instance_type = var.instance_type[0]
  monitoring = true
  vpc_security_group_ids = [aws_security_group.ec2.id]      ### var.vpc_security_group_ids       ###[aws_security_group.all_traffic.id]
  subnet_id = aws_subnet.public_subnet[0].id                                 ###aws_subnet.public_subnet[0].id
  root_block_device{
    volume_type="gp2"
    volume_size="20"
    encrypted=true
    kms_key_id = var.kms_key_id
    delete_on_termination=true
  }
  user_data = file("user_data_dexter.sh")

  lifecycle{
    prevent_destroy=false
    ignore_changes=[ ami ]
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  metadata_options { #Enabling IMDSv2
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tags={
    Name="${var.name}-Server"
    Environment = var.env
  }

}

resource "aws_eip" "eip_associate_ec2" {
  domain = "vpc"     ###vpc = true
}
resource "aws_eip_association" "eip_association_ec2" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.eip_associate_ec2.id
}
