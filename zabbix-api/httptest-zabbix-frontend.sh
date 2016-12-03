#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/util.sh"

host="Zabbix server"
application="Zabbix frontend"
name="Zabbix frontend"
zabbix_api httptest.get '{"output":"extend","selectSteps":"extend","filter":{"name":"'"$name"'"}}'
httptestid=$(echo "$JSON" | jq -r '.result[].httptestid')
variables='{user}=Admin\r\n{password}=zabbix'
step1='{"no":1,"name":"First page","url":"http://localhost/zabbix/index.php","status_codes":200,"required":"Zabbix SIA"}'
step2='{"no":2,"name":"Log in","url":"http://localhost/zabbix/index.php","posts":"name={user}&password={password}&enter=Sign in","status_codes":200,"variables": "{sid}=regex:name=\"sid\" value=\"([0-9a-z]{16})\""}'
# Admin uses Japanese locale
step3='{"no":3,"name":"Check login","url":"http://localhost/zabbix/index.php","status_codes":200,"required":"管理"}'
step4='{"no":4,"name":"Log out","url":"http://localhost/zabbix/index.php?reconnect=1&sid={sid}","status_codes":200}'
# Guest uses en_JS locale
step5='{"no":5,"name":"Check logout","url":"http://localhost/zabbix/index.php","status_codes":200,"required":"Username"}'
zabbix_api host.get '{"output":"extend","filter":{"host":["'"$host"'"]}}'
hostid=$(echo "$JSON" | jq -r '.result[].hostid')
if [ -z "$hostid" ]; then
    echo "'$host' not found" 1>&2
    exit 1
fi
application_get_id "$hostid" "$application"
applicationid="$ID"
if [ -z "$httptestid" ]; then
    zabbix_api httptest.create '{"hostid":"'"$hostid"'","applicationid":"'"$applicationid"'","name":"'"$name"'","variables":"'"$variables"'","steps":['"$step1,$step2,$step3,$step4,$step5"']}'
else
    zabbix_api httptest.update '{"httptestid":"'"$httptestid"'","hostid":"'"$hostid"'","applicationid":"'"$applicationid"'","name":"'"$name"'","variables":"'"$variables"'","steps":['"$step1,$step2,$step3,$step4,$step5"']}'
fi
