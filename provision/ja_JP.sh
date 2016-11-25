#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
sed -i \
    -e 's,//\(us\.\)\?archive\.ubuntu\.com,//jp.archive.ubuntu.com,' \
    -e 's,//httpredir\.debian\.org,//ftp.jp.debian.org,' \
    /etc/apt/sources.list
etckeeper commit 'Use JP mirror' || :
apt-get update || :
apt-get install -y language-pack-ja || {
  sed -i -e 's/^# ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen
  locale-gen
}
localectl set-locale LANG=ja_JP.UTF-8 || update-locale LANG=ja_JP.UTF-8
etckeeper commit 'Setup Japanese locale' || :
timedatectl set-timezone Asia/Tokyo || ln -sf ../usr/share/zoneinfo/Asia/Tokyo /etc/localtime
etckeeper commit 'Setup Japanese timezone' || :
