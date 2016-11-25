#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y aptitude
apt-get install -y clang
apt-get install -y lv
apt-get install -y source-highlight
apt-get install -y subversion
apt-get install -y zsh
[ "$(lsb_release -cs)" = "precise" ] || apt-get install -y silversearcher-ag
[[ "$(lsb_release -cs)" =~ ^(precise|trusty)$ ]] || apt-get install -y shellcheck
[[ "$(lsb_release -cs)" =~ ^(precise|trusty|jessie)$ ]] || apt-get install -y vim-editorconfig
