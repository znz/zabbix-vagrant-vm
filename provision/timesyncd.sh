#!/bin/bash
set -euxo pipefail
if [[ -f /etc/systemd/timesyncd.conf ]]; then
  sed -i -e 's/^#\?\(NTP\|Servers\)=.*/\1=ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp/' /etc/systemd/timesyncd.conf
  timedatectl set-ntp true
fi
etckeeper commit 'Setup NTP servers' || :
