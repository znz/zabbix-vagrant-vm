#!/bin/bash
set -euo pipefail
: ${ZABBIX_SERVER:=127.0.0.1}
: ${NASNE_HOSTNAME:=nasne}
: ${NASNE_IP?}
: ${REC_LOG_FILE:=/var/tmp/nasne.rec_log.$NASNE_IP}

sender () {
    if [ -t 1 ]; then
        zabbix_sender -z "$ZABBIX_SERVER" -s "$NASNE_HOSTNAME" -i -
    else
        zabbix_sender -z "$ZABBIX_SERVER" -s "$NASNE_HOSTNAME" -i - >/dev/null
    fi
}

JSON=$(curl -s "http://$NASNE_IP:64210/status/HDDInfoGet?id=0")
usedVolumeSize=$(echo "$JSON" | jq -r '.HDD.usedVolumeSize')
freeVolumeSize=$(echo "$JSON" | jq -r '.HDD.freeVolumeSize')
{
    echo "- nasne.hdd.free $usedVolumeSize"
    echo "- nasne.hdd.used $freeVolumeSize"
} | sender

JSON=$(curl -s "http://$NASNE_IP:64210/status/dtcpipClientListGet")
play=$(echo "$JSON" | jq -r '.number')
if [ "$(echo "$JSON" | jq -r '.client')" = "null" ]; then
    live=0
else
    live=$(echo "$JSON" | jq -r '.client | map(select(.liveInfo)) | length')
fi
{
    echo "- nasne.status.play $play"
    echo "- nasne.status.live $live"
} | sender

# 番組終了直後も録画状態が続いているので、その時の情報取得を避けるために少し sleep
sleep 10

JSON=$(curl -s "http://$NASNE_IP:64210/status/boxStatusListGet")
if [ "$(echo "$JSON" | jq -r '.tvTimerInfoStatus.nowId')" = "" ]; then
    rec=0
else
    rec=1
fi
networkId=$(echo "$JSON" | jq -r '.tuningStatus.networkId')
transportStreamId=$(echo "$JSON" | jq -r '.tuningStatus.transportStreamId')
serviceId=$(echo "$JSON" | jq -r '.tuningStatus.serviceId')
old_rec_log=
new_rec_log=
if [ "$rec" -eq 1 ]; then
    JSON=$(curl -s "http://$NASNE_IP:64210/status/channelInfoGet2?networkId=$networkId&transportStreamId=$transportStreamId&serviceId=$serviceId&withDescriptionLong=0")
    startDateTime=$(echo "$JSON" | jq -r '.channel.startDateTime')
    title=$(echo "$JSON" | jq -r '.channel.title')
    channel=$(echo "$JSON" | jq -r '.channel.service.serviceName')
    description=$(echo "$JSON" | jq -r '.channel.description' | tr $'\n' ' ')
    new_rec_log="$startDateTime $title ($channel) $description"
    if [ -f "$REC_LOG_FILE" ]; then
        old_rec_log=$(cat "$REC_LOG_FILE")
    fi
    echo "$new_rec_log" > "$REC_LOG_FILE"
fi
{
    echo "- nasne.status.rec $rec"
    if [ "$old_rec_log" != "$new_rec_log" -a -n "$new_rec_log" ]; then
        echo "- nasne.log.rec $new_rec_log"
    fi
} | sender
