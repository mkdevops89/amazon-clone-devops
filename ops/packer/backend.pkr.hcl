packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "backend" {
  ami_name      = "amazon-clone-backend-${formatdate("YYYYMMDDhhmm", timestamp())}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
}

build {
  name = "amazon-backend-ami"
  sources = [
    "source.amazon-ebs.backend"
  ]

  # Install Java 17 and updates
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y java-17-amazon-corretto-headless",
      "java -version"
    ]
  }

  # Create app user
  provisioner "shell" {
    inline = [
      "sudo useradd -m -s /bin/bash appuser",
      "sudo mkdir -p /opt/app",
      "sudo chown appuser:appuser /opt/app"
    ]
  }
}
