#!/bin/bash
set -euxo pipefail
if getent group systemd-journal; then
  mkdir -p /var/log/journal
  adduser vagrant systemd-journal
  etckeeper commit 'adduser vagrant systemd-journal' || :
fi
