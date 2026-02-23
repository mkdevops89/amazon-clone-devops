# Generate a new SSH Key specifically for Ansible to access the Bastion host
resource "tls_private_key" "ansible_bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ansible_bastion_keypair" {
  key_name   = "ansible-bastion-key"
  public_key = tls_private_key.ansible_bastion_key.public_key_openssh
}

# The Bastion Security Group (Allow SSH from anywhere for Ansible)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for Ansible managed bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In a real environment, restrict to the engineer's IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# The "Pet" EC2 Server
resource "aws_instance" "ansible_bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.ansible_bastion_keypair.key_name
  associate_public_ip_address = true

  tags = {
    Name        = "ansible-bastion"
    AnsibleNode = "true"
    Environment = "ops"
  }
}

# Save the private key locally so Ansible can use it immediately
resource "local_file" "private_key" {
  content         = tls_private_key.ansible_bastion_key.private_key_pem
  filename        = "${path.module}/../../ansible/keys/ansible-bastion.pem"
  file_permission = "0400"
}

output "bastion_public_ip" {
  description = "The public IP of the Ansible Bastion host"
  value       = aws_instance.ansible_bastion.public_ip
}
