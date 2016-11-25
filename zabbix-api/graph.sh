#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/util.sh"

zabbix_api item.get '{"output":"extend","templated":false,"search":{"key_":"icmppingsec"},"sortfield":"name"}'
upsert_graph "0 ICMP response time" $(echo "$JSON" | jq -r '.result[].itemid')

zabbix_api item.get '{"output":"extend","templated":false,"search":{"key_":"sslnotafter.rb[\"{HOST.CONN}\",993]"},"sortfield":"name"}'
upsert_graph "0 IMAPS Cert Remaining" $(echo "$JSON" | jq -r '.result[].itemid')

zabbix_api item.get '{"output":"extend","templated":false,"search":{"key_":"sslnotafter.rb[\"{HOST.CONN}\",636]"},"sortfield":"name"}'
upsert_graph "0 LDAPS Cert Remaining" $(echo "$JSON" | jq -r '.result[].itemid')

zabbix_api host.get '{"output":"extend"}'
host_json="$JSON"
for num in 1 2 3; do
    hostids=$(echo "$host_json" | jq -r '.result | map(select(.host | startswith("'"$num"' ")) | .hostid)')
    zabbix_api item.get '{"output":"extend","templated":false,"search":{"key_":"sslnotafter.rb[\"{HOST.CONN}\",443]"},"hostids":'"$hostids"',"sortfield":"name"}'
    upsert_graph "0 HTTPS Cert Remaining $num" $(echo "$JSON" | jq -r '.result[].itemid')
done
