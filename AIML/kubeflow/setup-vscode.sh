#! /bin/bash -eu

declare -a extensions=(
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/dracula-theme/vsextensions/theme-dracula/2.24.3/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/spmeesseman/vsextensions/vscode-taskexplorer/2.13.2/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-python/vsextensions/python/2023.15.12441006/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/tht13/vsextensions/python/0.2.3/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/donjayamanne/vsextensions/python-environment-manager/1.1.1/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/KevinRose/vsextensions/vsc-python-indent/1.18.0/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/VisualStudioExptTeam/vsextensions/vscodeintellicode/1.2.30/vspackage"
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/VisualStudioExptTeam/vsextensions/vscodeintellicode-completions/1.0.22/vspackage"
)
for extension in ${extensions[@]}; do
    curl -Lo /tmp/ext.vsix ${extension} \
        && code-server --install-extension /tmp/ext.vsix \
        && rm -f /tmp/ext.vsix
done
code-server --install-extension ms-toolsai.jupyter 
code-server --install-extension spmeesseman.vscode-taskexplorer 
code-server --list-extensions --show-versions