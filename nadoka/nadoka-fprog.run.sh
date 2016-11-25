#!/bin/sh
exec 2>&1
logger -s -t runsv -- start "$(basename "$(pwd)")"
USER=vagrant
HOME="$(getent passwd $USER | awk -F: '{print $6}')"
export HOME
exec chpst -u ":$(id -u $USER):$(id -g $USER)" "/vagrant/nadoka/run-fprog.sh"
