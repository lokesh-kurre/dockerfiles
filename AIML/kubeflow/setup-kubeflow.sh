#! /bin/bash -eu

export DEBIAN_FRONTEND=noninteractive
export KUBECTL_ARCH="amd64"
export KUBECTL_VERSION=v1.21.0
export CODESERVER_VERSION=${CODESERVER_VERSION:-"v4.16.0"}

apt-get update
apt-get install -q --yes --no-install-recommends \
    apt-transport-https \
    bzip2 git gnupg2  locales lsb-release \
    software-properties-common tzdata binutils nginx libsecret-1-dev apache2-utils

curl -sL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" -o /usr/local/bin/kubectl
curl -sL "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256" -o /tmp/kubectl.sha256 
echo "$(cat /tmp/kubectl.sha256) /usr/local/bin/kubectl" | sha256sum --check 
rm /tmp/kubectl.sha256 
chmod +x /usr/local/bin/kubectl 

curl -sL "https://github.com/cdr/code-server/releases/download/${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION/v/}_amd64.deb" -o /tmp/code-server.deb
dpkg -i /tmp/code-server.deb 
rm -f /tmp/code-server.deb 

code-server --install-extension VisualStudioExptTeam.vscodeintellicode 
code-server --install-extension ms-python.python
code-server --install-extension ms-python.vscode-pylance 
code-server --install-extension ms-toolsai.jupyter 
code-server --install-extension spmeesseman.vscode-taskexplorer 
code-server --list-extensions --show-versions