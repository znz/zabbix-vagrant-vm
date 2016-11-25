#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends runit || :
apt-get install -y git subversion || :
SRCDIR=/vagrant/nadoka
mkdir -p /etc/sv/nadoka-fprog/log
install "$SRCDIR/log-run.sh" "/etc/sv/log-run"
ln -sf "../../log-run" "/etc/sv/nadoka-fprog/log/run"
ln -snf "/var/run/sv.nadoka-fprog.log" "/etc/sv/nadoka-fprog/log/supervise"
ln -snf "/var/run/sv.nadoka-fprog" "/etc/sv/nadoka-fprog/supervise"
install "$SRCDIR/nadoka-fprog.run.sh" "/etc/sv/nadoka-fprog/run"
ln -snf "../sv/nadoka-fprog" "/etc/service/nadoka-fprog"
mkdir -p /etc/sv/nadoka-slack/log
ln -sf "../../log-run" "/etc/sv/nadoka-slack/log/run"
ln -snf "/var/run/sv.nadoka-slack.log" "/etc/sv/nadoka-slack/log/supervise"
ln -snf "/var/run/sv.nadoka-slack" "/etc/sv/nadoka-slack/supervise"
install "$SRCDIR/nadoka-slack.run.sh" "/etc/sv/nadoka-slack/run"
ln -snf "../sv/nadoka-slack" "/etc/service/nadoka-slack"
etckeeper commit "Setup nadoka" || :
adduser vagrant adm
etckeeper commit "Add vagrant user to adm group" || :
