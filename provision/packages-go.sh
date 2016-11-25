#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
case "$(lsb_release -cs)" in
  precise)
    ;;
  trusty)
    add-apt-repository -y ppa:ubuntu-lxc/lxd-stable
    apt-get update
    apt-get install -y golang
    ;;
  *)
    apt-get install -y golang
    ;;
esac
