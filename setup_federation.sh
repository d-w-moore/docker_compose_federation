#!/bin/bash

su_replace() {
    test $# -lt 3 && { return 1; }
    local cmd file=$1 new=${2#.} old=${3#.}
    for cmd in "chown" "chmod"; do command $cmd --reference="$file" "$file.$new" ; done &&\
    mv $file{,.$old} &&\
    mv $file{.$new,}
}

[ -r /tmp/federate_with.txt ] || exit 1
typeset -A P=$(cat /tmp/federate_with.txt)

SERVER_CONFIG=/etc/irods/server_config.json

STATUS=-1
if [[ ! $(jq ".federation?" $SERVER_CONFIG) =~ ^\ *\[\ *\]\ *$ ]]; then
    echo >&2 "Federation config already set"
    exit 2
else
    EPOCH=`date +%s`
    jq '.federation+=[{
        "catalog_provider_hosts": ["'${P[hn]}'"],
        "negotiation_key": "'${P[nk]}'",
        "zone_key":  "'${P[zk]}'",
        "zone_name": "'${P[zn]}'",
        }]' $SERVER_CONFIG > $SERVER_CONFIG.new &&\
        su_replace $SERVER_CONFIG ".new" ".previous.$EPOCH"
        STATUS=$?
fi
echo "\$STATUS=${STATUS}"

IRODS_REMOTE_USER="$1"

#sudo su - irods -c "iadmin mkuser bobby rodsuser"
#sudo su - irods -c "iadmin moduser bobby password bpass"
#sudo su - irods -c "iadmin mkzone ${P[zn]} remote ${P[hn]}:${P[zp]}"
##sudo su - irods -c "iadmin mkzone ${P[zn]} remote ${P[hn]}:${P[zp]}"
#---------------------------
#for x in ${!P[*]}; do
#    echo $((++y)) $x "${P[$x]}"
#done; :
##1 nk 32_byte_server_negotiation_key_B
##2 hn icatB
##3 zn zoneB
##4 zk TEMP__B___ZONE_KEY
##5 zp 8882
