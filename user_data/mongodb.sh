#!/bin/bash

# Cập nhật hệ thống
sudo yum update -y

# Cài đặt Docker
sudo amazon-linux-extras enable docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Cài đặt Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Tạo thư mục cho MongoDB
mkdir -p ~/mongodb && cd ~/mongodb

# Tạo file docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  mongodb:
    image: mongo:5.0
    container_name: mongodb
    restart: always
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: testpass
    volumes:
      - mongodb_data:/data/db
volumes:
  mongodb_data:
    driver: local
EOF

# Khởi động MongoDB
sudo /usr/local/bin/docker-compose up -d
