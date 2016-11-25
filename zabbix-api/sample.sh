#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/util.sh"

: ${EXAMPLE:=}

typeset -A protocols
protocols["HTTPS"]=443
hostgroups=()
hostgroups+=("0 My Templates" "0 Certificate Templates")
hostgroups+=("1 ping監視" "1 Routers" "1 Certificate")

hostgroupids=()
for hostgroup in "${hostgroups[@]}"; do
    hostgroup_get_id "$hostgroup"
    hostgroupids+=($ID)
done

hostgroup_get_id "Hypervisors"
hostgroup_get_id "Linux servers"
hostgroup_get_id "Templates"
hostgroup_get_id "Virtual machines"

unset hostgroup_json
if [ -n "$DEBUG" ]; then
    for hostgroup in "${hostgroups[@]}"; do
	echo_var "$hostgroup" groupid
    done
    echo_var "Hypervisors" groupid
    echo_var "Linux servers" groupid
    echo_var "Templates" groupid
    echo_var "Virtual machines" groupid
fi

template_get_id "Template App SSH Service" "[$groupid_Templates]"
template_get_id "Template ICMP Ping" "[$groupid_Templates]"
template_get_id "Template OS Linux" "[$groupid_Templates]"

templateids=()
for protocol in "${!protocols[@]}"; do
    template_get_id "0 My Template App $protocol Certificate" "[$groupid_Templates,$groupid_0_My_Templates,$groupid_0_Certificate_Templates]"
    templateids+=($ID)
done

unset template_json
if [ -n "$DEBUG" ]; then
    echo_var "Template App SSH Service" templateid
    echo_var "Template ICMP Ping" templateid
    echo_var "Template OS Linux" templateid
    for protocol in "${!protocols[@]}"; do
	echo_var "0 My Template App $protocol Certificate" templateid
    done
fi

# application
if [ -n "$EXAMPLE" ]; then
    application_get_id "$templateid_Template_App_SSH_Service" "SSH service"
    application_get_id "$templateid_Template_OS_Linux" "General"
    application_get_id "$templateid_Template_OS_Linux" "OS"
fi

applicationids=()
for protocol in "${!protocols[@]}"; do
    eval templateid=\$templateid_0_My_Template_App_${protocol}_Certificate
    application_get_id "$templateid" "Cert Remaining" "$protocol"
    applicationids+=($ID)
    unset templateid
done

unset application_jsons
if [ -n "$DEBUG" ]; then
    if [ -n "$EXAMPLE" ]; then
	echo_var "SSH service" applicationid
	echo_var "General" applicationid
	echo_var "OS" applicationid
    fi
    for protocol in "${!protocols[@]}"; do
	echo_var "Cert Remaining $protocol" applicationid
    done
fi

# item
if [ -n "$EXAMPLE" ]; then
    item_get_id "$templateid_Template_OS_Linux" 'System uptime' 0 'system.uptime' 3 "[$applicationid_General,$applicationid_OS]" 600 ''
fi
itemids=()
for protocol in "${!protocols[@]}"; do
    item_get_id_of_cert_remaining "$protocol"
    itemids+=($ID)
done

# trigger
triggerids=()
for protocol in "${!protocols[@]}"; do
    trigger_get_id_of_cert "$protocol" "${protocols[$protocol]}"
done

# host
get_hosts () {
    local dns
    local ip
    dns=localhost
    host_get_id "1 $dns" "[$groupid_1_ping_,$groupid_Linux_servers]" "$(agent_dns_interfaces "$dns")" "[$templateid_Template_ICMP_Ping,$templateid_Template_OS_Linux]"
    ip=127.0.0.1
    host_get_id "1 $ip" "[$groupid_1_ping_,$groupid_Linux_servers]" "$(agent_ip_interfaces "$ip")" "[$templateid_Template_ICMP_Ping,$templateid_Template_OS_Linux]"
    unset host_json
}
get_hosts

if [ -n "$DEBUG" ]; then
    set > /tmp/set.txt
fi

# delete
if [ -n "$DELETE" ]; then
    #zabbix_api host.delete "[\"$hostid\"]"
    zabbix_api trigger.delete "$(echo ${triggerids[@]} | sed 's/^/["/;s/ /","/g;s/$/"]/')"
    zabbix_api item.delete "$(echo ${itemids[@]} | sed 's/^/["/;s/ /","/g;s/$/"]/')"
    zabbix_api application.delete "$(echo ${applicationids[@]} | sed 's/^/["/;s/ /","/g;s/$/"]/')"
    zabbix_api template.delete "$(echo ${templateids[@]} | sed 's/^/["/;s/ /","/g;s/$/"]/')"
    zabbix_api hostgroup.delete "$(echo ${hostgroupids[@]} | sed 's/^/["/;s/ /","/g;s/$/"]/')"
fi
