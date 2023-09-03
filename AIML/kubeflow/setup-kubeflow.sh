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

curl -L "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" -o /usr/local/bin/kubectl
curl -L "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256" -o /tmp/kubectl.sha256 
echo "$(cat /tmp/kubectl.sha256) /usr/local/bin/kubectl" | sha256sum --check 
rm /tmp/kubectl.sha256 
chmod +x /usr/local/bin/kubectl 

curl -L "https://github.com/cdr/code-server/releases/download/${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION/v/}_amd64.deb" -o /tmp/code-server.deb
dpkg -i /tmp/code-server.deb 
rm -f /tmp/code-server.deb 

declare -a extensions=("https://marketplace.visualstudio.com/_apis/public/gallery/publishers/dracula-theme/vsextensions/theme-dracula/2.24.3/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/spmeesseman/vsextensions/vscode-taskexplorer/2.13.2/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/2023.15.12441006/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/tht13/vsextensions/python/0.2.3/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/donjayamanne/vsextensions/python-environment-manager/1.1.1/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/KevinRose/vsextensions/vsc-python-indent/1.18.0/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/VisualStudioExptTeam/vsextensions/vscodeintellicode/1.2.30/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/VisualStudioExptTeam/vsextensions/vscodeintellicode-completions/1.0.22/vspackage"
    )
for extension in ${extensions[@]}; do
    wget -O /tmp/ext.vsix ${extension}
    code-server --install-extension /tmp/ext.vsix
    rm -f /tmp/ext.vsix
done
code-server --install-extension ms-toolsai.jupyter 
code-server --install-extension spmeesseman.vscode-taskexplorer 
code-server --list-extensions --show-versions