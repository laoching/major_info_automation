provider "aws" {
  region = "ap-northeast-2"  # 원하는 AWS 리전을 설정하세요.
}

# 키 페어 생성
resource "tls_private_key" "first_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "first_key_pair" {
  key_name   = "first_key_pair"
  public_key = tls_private_key.first_key.public_key_openssh
}

# make security group for ssh connect
resource "aws_security_group" "allow_ssh_http" {
  name	= "allow_ssh_http"
  description = "created by terraform, allow ssh and http"
  vpc_id	= "[your vpc id]"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# EC2 인스턴스 생성
resource "aws_instance" "first_instance" {
  ami           = "ami-024ea438ab0376a47"  # ubuntu24.04 lts
  instance_type = "t2.micro"  # 원하는 인스턴스 타입을 설정하세요.

  # 생성된 키 페어를 사용
  key_name = aws_key_pair.first_key_pair.key_name

  # select security group
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # 사용자 데이터를 통해 Docker 및 Docker Compose 설치
  user_data = <<-EOF
    #!/bin/bash
    # 업데이트 및 Docker 설치
    apt-get update -y
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # add the repository to apt sources:
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu focal stable"
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu focal stable" | tee /etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Docker Compose 설치
    curl -L "https://github.com/docker/compose/releases/download/2.33.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

    # docker run using docker compose
    cat <<EOT >> /home/ubuntu/docker-compose.yml
    version: '3'
    services:
      keycloak:
        image: quay.io/keycloak/keycloak:26.1.3
        container_name: keycloak
        ports:
          - 8080:8080
        volumes:
          - keycloak_data:/opt/keycloak
        environment:
          - KC_BOOTSTRAP_ADMIN_USERNAME=admin
          - KC_BOOTSTRAP_ADMIN_PASSWORD=admin
        command:
          - start-dev
    volumes:
      keycloak_data:
    EOT
  EOF

  tags = {
    Name = "first_terra_instance"
  }
}

# 키 페어의 비공개 키를 출력
output "private_key_pem" {
  value     = tls_private_key.first_key.private_key_pem
  sensitive = true
}

output "instance_id" {
  value = aws_instance.first_instance.id
}

output "public_ip" {
  value = aws_instance.first_instance.public_ip
}
