#! /bin/bash -eu

export DEBIAN_FRONTEND=noninteractive

locale-gen "$LANG"

apt-get update

apt-get install -q --yes --no-install-recommends \
    apt-utils make gettext pkg-config tzdata`# Basic Utility Software` \
    ca-certificates openssl `# CA Certificates & SSL tool` \
    curl wget `# API CALL utility` \
    vim nano tmux `# Text Editor & Tmux` \
    telnet traceroute net-tools inetutils-ping procps `# Network utility` \
    gnupg tar unzip unrar zip `# File Compression Utility` \
    libgl1 libglib2.0-0 libgtk2.0-dev `# OPENGL library` \
    tini  `# PID-1 for zombie subreaper`



# rm -rf /var/cache/apt/* /var/lib/apt/*