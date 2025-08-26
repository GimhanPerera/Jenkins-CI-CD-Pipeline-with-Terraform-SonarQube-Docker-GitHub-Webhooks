#!/bin/bash

set -e  # Exit on error

# Update and install dependencies
sudo apt update -y
sudo apt install -y unzip wget openjdk-17-jdk

# Create a user for SonarQube
sudo useradd -m -d /opt/sonarqube -s /bin/bash sonarqube || true

# Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
sudo unzip sonarqube-10.4.1.88267.zip
sudo mv sonarqube-10.4.1.88267 sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# System tuning required by SonarQube
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set ulimit for sonarqube user
cat <<EOF | sudo tee /etc/security/limits.d/99-sonarqube.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF

# Create systemd service for SonarQube
cat <<EOF | sudo tee /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube