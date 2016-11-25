#!/bin/bash
set -euxo pipefail
apt-get install -y openvpn
for crt in ca.crt zbx3.crt; do
  install -D -m644 "/vagrant/tmp/openvpn/$crt" "/etc/openvpn/keys/$crt"
done
for key in ta.key zbx3.key; do
  install -D -m600 "/vagrant/tmp/openvpn/$key" "/etc/openvpn/keys/$key"
done
install -D -m644 "/vagrant/tmp/openvpn/client.conf" "/etc/openvpn/client.conf"
systemctl enable openvpn@client
systemctl start openvpn@client
ufw allow out proto udp to "$(getent hosts ns6.n-z.jp | awk '{print $1}')" port "$(awk '$1=="remote"{print $3}' /etc/openvpn/client.conf)"
etckeeper commit "Setup OpenVPN" || :
