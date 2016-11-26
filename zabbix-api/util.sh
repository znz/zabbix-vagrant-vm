#!/bin/bash
set -euo pipefail

: ${API_URL:=http://localhost/zabbix/api_jsonrpc.php}
: ${ZABBIX_USER:=Admin}
: ${PASSWORD:=zabbix}
: ${DEBUG=}
: ${SERIAL:=1}

if [ -n "$DEBUG" ]; then
    : ${TOKEN:=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d '{"jsonrpc":"2.0","method":"user.login","params":{"user":"'"$ZABBIX_USER"'","password":"'"$PASSWORD"'"},"id":'"$SERIAL"'}' "$API_URL" | tee /tmp/login.json | jq -r '.result')}
else
    : ${TOKEN:=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d '{"jsonrpc":"2.0","method":"user.login","params":{"user":"'"$ZABBIX_USER"'","password":"'"$PASSWORD"'"},"id":'"$SERIAL"'}' "$API_URL" | jq -r '.result')}
fi

debug () {
    if [ -n "$DEBUG" ]; then
	echo "$@"
    fi
}

zabbix_api () {
    local method="$1"
    local params="$2"
    SERIAL=$((SERIAL+1))
    local json='{"auth":"'"$TOKEN"'","jsonrpc":"2.0","method":"'"$method"'","id":'"$SERIAL"',"params":'"$params"'}'
    debug "$json"
    if [ -n "$DEBUG" ]; then
	JSON=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d "$json" "$API_URL" | tee /tmp/z.json)
    else
	JSON=$(curl -s -X POST -H "Content-Type: application/json-rpc" -d "$json" "$API_URL")
    fi
    local error
    error=$(echo "$JSON" | jq '.error')
    if [ x"$error" != x"null" ]; then
	echo "$error" 1>&2
	return 1
    fi
}

to_var_name () {
    echo "$1" | sed 's/[^A-Za-z0-9]\+/_/g'
}

echo_var () {
    local name="$1"
    local prefix="$2"
    eval var=\$${prefix}_$(to_var_name "$name")
    echo "$name $prefix: $var"
}

# hostgroup
hostgroup_json=

hostgroup_get () {
    zabbix_api hostgroup.get '{"output":"extend"}'
    hostgroup_json="$JSON"
}

hostgroup_get_id () {
    if [ -z "$hostgroup_json" ]; then
	hostgroup_get
    fi
    local name="$1"
    local groupid
    groupid=$(echo "$hostgroup_json" | jq -r '.result[] | select(.name == "'"$name"'") | .groupid')
    if [ -z "$groupid" ]; then
	zabbix_api hostgroup.create '{"name":"'"$name"'"}'
	groupid=$(echo "$JSON" | jq -r '.result.groupids[]')
    fi
    eval groupid_$(to_var_name "$name")=\$groupid
    ID=$groupid
}

# template
template_json=

template_get () {
    zabbix_api template.get '{"output":"extend"}'
    template_json="$JSON"
}

template_get_id () {
    if [ -z "$template_json" ]; then
	template_get
    fi
    local host="$1"
    local groups="$2"
    local templateid
    templateid=$(echo "$template_json" | jq -r '.result[] | select(.host == "'"$host"'") | .templateid')
    if [ -z "$templateid" ]; then
	groups=$(echo "$groups" | jq -c 'map({groupid:.})')
	zabbix_api template.create '{"host":"'"$host"'","groups":'"$groups"'}'
	templateid=$(echo "$JSON" | jq -r '.result.templateids[]')
    fi
    eval templateid_$(to_var_name "$host")=\$templateid
    ID=$templateid
}

# application
typeset -A application_jsons

application_get () {
    local hostid="$1"
    zabbix_api application.get '{"output":"extend","hostids":"'"$hostid"'"}'
    application_jsons[$hostid]="$JSON"
}

application_get_id () {
    local hostid="$1"
    local name="$2"
    local suffix="${3:+_}${3:-}"
    if [ -z "${application_jsons[$hostid]:-}" ]; then
	application_get "$hostid"
    fi
    local applicationid
    applicationid=$(echo "${application_jsons[$hostid]}" | jq -r '.result[] | select(.name == "'"$name"'") | .applicationid')
    if [ -z "$applicationid" ]; then
	zabbix_api application.create '{"name":"'"$name"'","hostid":"'"$hostid"'"}'
	applicationid=$(echo "$JSON" | jq -r '.result.applicationids[]')
    fi
    debug applicationid_$(to_var_name "$name")${suffix}=\$applicationid
    eval applicationid_$(to_var_name "$name")${suffix}=\$applicationid
    ID=$applicationid
}

# item
item_get_id () {
    local hostid="$1"
    local name="$2"
    local type="$3"
    local key_="$4"
    local value_type="$5"
    local applications="$6"
    local delay="$7"
    local misc="$8"
    key_=$(echo "$key_" | sed 's/"/\\"/g')
    local itemid
    zabbix_api item.get '{"output":"extend","hostids":"'"$hostid"'","search":{"key_":"'"$key_"'"},"sortfield":"name"}'
    itemid=$(echo "$JSON" | jq -r '.result[].itemid')
    if [ -z "$itemid" ]; then
	applications=$(echo "$applications" | jq -c 'map(tostring)')
	zabbix_api item.create '{"name":"'"$name"'","key_":"'"$key_"'","hostid":"'"$hostid"'","type":'"$type"',"value_type":'"$value_type"',"applications":'"$applications"',"delay":'"$delay"''"$misc"'}'
	itemid=$(echo "$JSON" | jq -r '.result.itemids[]')
    fi
    debug "$key_ itemid: $itemid"
    ID=$itemid
}

item_get_id_of_cert_remaining () {
    local protocol="$1"
    local templateid
    local applicationid
    local port
    eval templateid="\$templateid_0_My_Template_App_$(to_var_name "$protocol")_Certificate"
    eval applicationid="\$applicationid_Cert_Remaining_$(to_var_name "$protocol")"
    port="${protocols[$protocol]}"
    item_get_id "$templateid" "0 $protocol Cert Remaining" 10 "sslnotafter.rb[\"{HOST.CONN}\",$port]" 0 "[$applicationid]" 3600 ',"units":"uptime","history":7'
}

# trigger
trigger_get_id () {
    local description="$1"
    local expression="$2"
    local priority="$3"
    expression=$(echo "$expression" | sed 's/"/\\"/g')
    zabbix_api trigger.get '{"filter":{"description":"'"$description"'"},"templated":true}'
    local triggerid
    triggerid=$(echo "$JSON" | jq -r '.result[].triggerid')
    if [ -z "$triggerid" ]; then
	zabbix_api trigger.create '{"description":"'"$description"'","expression":"'"$expression"'","priority":'"$priority"'}'
	triggerid=$(echo "$JSON" | jq -r '.result.triggerids[]')
    fi
    debug "$description triggerid: $triggerid"
    ID=$triggerid
}

trigger_get_id_of_cert () {
    local protocol="$1"
    local port="$2"
    local day
    trigger_get_id "$protocol Cert is expired on {HOST.NAME}" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].last(0)}<0" 5
    triggerids+=($ID)
    day=7
    trigger_get_id "$protocol Cert is about to expire on {HOST.NAME} ($day days)" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].last(0)}<$((86400*$day))" 4
    triggerids+=($ID)
    day=14
    trigger_get_id "$protocol Cert is about to expire on {HOST.NAME} ($day days)" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].last(0)}<$((86400*$day))" 3
    triggerids+=($ID)
    day=30
    trigger_get_id "$protocol Cert is about to expire on {HOST.NAME} ($day days)" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].last(0)}<$((86400*$day))" 2
    triggerids+=($ID)
    day=31
    trigger_get_id "$protocol Cert is about to expire on {HOST.NAME} ($day days)" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].last(0)}<$((86400*$day))" 1
    triggerids+=($ID)
    trigger_get_id "$protocol Cert is renewal on {HOST.NAME}" "{0 My Template App $protocol Certificate:sslnotafter.rb[\"{HOST.CONN}\",$port].change(0)}>0" 1
    triggerids+=($ID)
}

# host
host_json=

host_get () {
    zabbix_api host.get '{"output":"extend"}'
    host_json="$JSON"
}

host_get_id () {
    local host="$1"
    local groups="$2"
    local interfaces="$3"
    local templates="$4"
    if [ -z "$host_json" ]; then
	host_get
    fi
    hostid=$(echo "$host_json" | jq -r '.result[] | select(.host == "'"$host"'") | .hostid')
    if [ -z "$hostid" ]; then
	groups=$(echo "$groups" | jq -c 'map({groupid:.})')
	templates=$(echo "$templates" | jq -c 'map({templateid:.})')
	zabbix_api host.create '{"host":"'"$host"'","groups":'"$groups"',"interfaces":'"$interfaces"',"templates":'"$templates"'}'
	hostid=$(echo "$JSON" | jq -r '.result.hostids[]')
    fi
    eval hostid_$(to_var_name "$host")=\$hostid
    ID=$hostid
}

agent_ip_interfaces () {
    local ip="$1"
    local port="${2:-10050}"
    echo '[{"dns":"","ip":"'"$ip"'","main":1,"port":"'"$port"'","type":1,"useip":1}]'
}

agent_dns_interfaces () {
    local dns="$1"
    local port="${2:-10050}"
    echo '[{"dns":"'"$dns"'","ip":"","main":1,"port":"'"$port"'","type":1,"useip":0}]'
}

snmp_ip_interfaces () {
    local ip="$1"
    local port="${2:-161}"
    echo '[{"dns":"","ip":"'"$ip"'","main":1,"port":"'"$port"'","type":1,"useip":1}]'
}

# graph
upsert_graph () {
    local name="$1"; shift
    # palette from /usr/share/zabbix/js/functions.js
    local palette=('1A7C11' 'F63100' '2774A4' 'A54F10' 'FC6EA3' '6C59DC' 'AC8C14' '611F27' 'F230E0' '5CCD18' 'BB2A02' '5A2B57' '89ABF8' '7EC25C' '274482' '2B5429' '8048B4' 'FD5434' '790E1F' '87AC4D' 'E89DF4')
    local current_color=0
    local color
    local graphid
    local itemid
    local gitems
    if [ -z "${1:-}" ]; then
	echo "'$name' without itemids" 1>&2
	return 1
    fi
    zabbix_api item.get '{"output":"extend","itemids":"'"$1"'"}'
    zabbix_api graph.get '{"output":"extend","itemids":"'"$1"'"}'
    graphid=$(echo "$JSON" | jq -r '.result[] | select(.name == "'"$name"'") | .graphid')

    gitems=''
    for itemid in "$@"; do
	color="${palette[$current_color]}"
	current_color=$(((current_color+1) % ${#palette[@]}))
	gitems="${gitems}{\"itemid\":\"$itemid\",\"color\":\"$color\"},"
    done
    gitems="${gitems%,}"
    if [ -z "$graphid" ]; then
	zabbix_api graph.create '{"name":"'"$name"'","width":900,"height":200,"gitems":['"$gitems"']}'
    else
	zabbix_api graph.update '{"graphid":"'"$graphid"'","gitems":['"$gitems"']}'
    fi
}
