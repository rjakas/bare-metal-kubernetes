#!/bin/bash

# dependency list
DOCKER_INSTALLED=false
KIND_INSTALLED=false
TERRAFORM_INSTALLED=false
KUBECTL_INSTALLED=false

# reinstall flags
# In case you have a dependency but want to update to latest version, for docker its same script set as installing fresh
REINSTALL_DOCKER=false

# check dependencies exist
if command -v docker &> /dev/null; then
  DOCKER_INSTALLED=true
  echo "Docker is installed on the system"
fi


if command -v kind &> /dev/null; then
  KIND_INSTALLED=true
  echo "Kind is installed on the system"
fi


if command -v terraform &> /dev/null; then
  TERRAFORM_INSTALLED=true
  echo "Terraform is installed on the system"
fi


if command -v kubectl &> /dev/null; then
  KUBECTL_INSTALLED=true
  echo "Kubectl is installed on the system"
fi


if ! $DOCKER_INSTALLED || $REINSTALL_DOCKER; then
  if $REINSTALL_DOCKER; then
    echo "Reinstall docker command has been triggered..."
  fi
  echo "Installing docker..."
  # uninstall old versions and conflicting packages
  sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

  # add docker's official GPG key
  sudo apt update
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # add the respository to apt sources
  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt update

  # install docker
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi


if ! $KIND_INSTALLED; then
  echo "installing kind from release binaries"
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind 
fi

if ! $TERRAFORM_INSTALLED; then
  echo "installing terraform"

  wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform
fi

if ! $KUBECTL_INSTALLED; then
  echo "installing kubectl"

  # download latest release
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  # download checksum
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  # check binary against checksum
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  # install kubectl
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

fi