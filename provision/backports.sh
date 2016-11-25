#!/bin/bash
set -euxo pipefail
cat >/etc/apt/sources.list.d/backports.list <<EOF
deb http://ftp.jp.debian.org/debian jessie-backports main
deb-src http://ftp.jp.debian.org/debian jessie-backports main
EOF
apt-get update
etckeeper commit 'Add jessie-backports' || :
