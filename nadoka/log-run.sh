#!/bin/sh
loguser=uucp
logdir="/var/log/runit/$(basename "$(dirname "$(pwd)")")"
umask 027
if [ ! -d /var/log/runit ]; then
    install -m 750 -o "$loguser" -g adm -d /var/log/runit
fi
install -m 750 -o "$loguser" -g adm -d "$logdir"
cd "$logdir"
exec chpst -u "$loguser:adm" svlogd -tt "$logdir"
