#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update || :
apt-get install -y etckeeper git
sed -i -e 's/^#VCS="git"/VCS="git"/' -e 's/^VCS="bzr"/#VCS="bzr"/' -e 's/^GIT_COMMIT_OPTIONS=""/GIT_COMMIT_OPTIONS="-v"/' /etc/etckeeper/etckeeper.conf
etckeeper init 'Initial commit'
etckeeper commit 'Setup etckeeper' || :
