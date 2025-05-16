# EKS-Terraform

# EKS-Terraform

On the cluster jumpbox, install the following

Install AWS CLI

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws configure

Install Kubectl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
# Verify the binary
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# Check kubectl version
kubectl version --client

Set kubeconfig

aws eks --region ap-south-1 update-kubeconfig --name devopsshack-cluster

=============================================
=============================================

**Set Up Java, JEnkins, Docker, Anssible**

sudo dnf install java-11-amazon-corretto -y

sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install jenkins -y

sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

sudo dnf install ansible -y

sudo systemctl start jenkins
sudo systemctl enable jenkins

java -version

docker —version

ansible —version

