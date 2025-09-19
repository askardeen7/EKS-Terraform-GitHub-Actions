#!/bin/bash
set -e

echo "=== Updating system ==="
sudo apt update -y && sudo apt upgrade -y

# -------------------------
# Docker
# -------------------------
echo "=== Installing Docker ==="
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl restart docker

# -------------------------
# Java 17 (for Jenkins & SonarQube)
# -------------------------
echo "=== Installing Java 17 ==="
sudo apt install -y fontconfig openjdk-17-jre
java -version

# -------------------------
# Jenkins
# -------------------------
echo "=== Installing Jenkins ==="
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# -------------------------
# SonarQube (Standalone)
# -------------------------
echo "=== Installing SonarQube ==="
sudo apt install unzip -y
sudo adduser --disabled-password --gecos "" sonarqube || true
sudo -u sonarqube bash <<EOF
cd ~
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip
unzip -q sonarqube-9.4.0.54424.zip
chmod -R 755 sonarqube-9.4.0.54424
cd sonarqube-9.4.0.54424/bin/linux-x86-64/
./sonar.sh start
EOF

# -------------------------
# AWS CLI v2
# -------------------------
echo "=== Installing AWS CLI v2 ==="
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip
aws --version || echo "AWS CLI not installed correctly"

# -------------------------
# kubectl
# -------------------------
echo "=== Installing kubectl ==="
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
kubectl version --client || echo "kubectl not installed correctly"

# -------------------------
# Terraform
# -------------------------
echo "=== Installing Terraform ==="
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update -y
sudo apt install terraform -y
terraform -version || echo "Terraform not installed correctly"

# -------------------------
# Trivy
# -------------------------
echo "=== Installing Trivy ==="
sudo apt install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt update -y
sudo apt install trivy -y
trivy --version

# -------------------------
# Final Checks
# -------------------------
echo "=== Installation complete ==="
echo "Versions installed:"
aws --version
kubectl version --client
terraform -version
docker --version
java -version
trivy --version
