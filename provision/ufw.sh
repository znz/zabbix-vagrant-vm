#!/bin/bash
set -euxo pipefail
apt-get install -y ufw
UFW=ufw
$UFW default DENY
sed -i -e 's/DEFAULT_OUTPUT_POLICY="ACCEPT"/DEFAULT_OUTPUT_POLICY="REJECT"/' /etc/default/ufw
if ! grep -q '##BEGIN' /etc/ufw/before.rules; then
  TEMP=$(mktemp)
  {
    head -n-2 /etc/ufw/before.rules
    cat <<END
##BEGIN
# ok icmp codes for OUTPUT
-A ufw-before-output -p icmp --icmp-type destination-unreachable -j ACCEPT
-A ufw-before-output -p icmp --icmp-type source-quench -j ACCEPT
-A ufw-before-output -p icmp --icmp-type time-exceeded -j ACCEPT
-A ufw-before-output -p icmp --icmp-type parameter-problem -j ACCEPT
-A ufw-before-output -p icmp --icmp-type echo-request -j ACCEPT

-A ufw-before-input -s 224.0.0.0/4 -j ACCEPT
-A ufw-before-input -d 224.0.0.0/4 -j ACCEPT
-A ufw-before-output -s 224.0.0.0/4 -j ACCEPT
-A ufw-before-output -d 224.0.0.0/4 -j ACCEPT
##END

END
    tail -2 /etc/ufw/before.rules
  } > "$TEMP"
  cat "$TEMP" > /etc/ufw/before.rules
  rm -f "$TEMP"
fi

$UFW allow out 22/tcp
#$UFW allow out 25/tcp
$UFW allow out 53
$UFW allow out 80,443/tcp
$UFW allow out 123/udp
$UFW allow out 465,587,993,995/tcp
$UFW allow out 636/tcp
$UFW allow out 2401,3690,9418/tcp
$UFW allow out 6667,6697/tcp
$UFW allow out 8080/tcp
$UFW allow out 10050/tcp
$UFW allow out 11371/tcp

$UFW allow 22/tcp; $UFW limit 22/tcp
#$UFW allow 25/tcp
$UFW allow 80,443/tcp

$UFW enable
etckeeper commit 'Setup firewall' || :
