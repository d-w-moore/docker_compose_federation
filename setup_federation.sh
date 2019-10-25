#!/bin/bash

su_replace() {
    test $# -lt 3 && { return 1; }
    local cmd file=$1 new=${2#.} old=${3#.}
    for cmd in "chown" "chmod"; do command $cmd --reference="$file" "$file.$new" ; done &&\
    mv $file{,.$old} &&\
    mv $file{.$new,}
}

irods_env_var() {
    su - ${2:-irods} -c "jq .'$1' ~/.irods/irods_environment.json"
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

su - irods -c '$HOME/irodsctl restart'

su - irods -c "iadmin mkuser bobby rodsuser"
su - irods -c "iadmin moduser bobby password bpass"
su - irods -c "iadmin mkzone ${P[zn]} remote ${P[hn]}:${P[zp]}"

IRODS_USER_NAME=$(irods_env_var irods_user_name)
IRODS_ZONE_NAME=$(irods_env_var irods_zone_name)
REMOTE_USER_HOME="/$IRODS_ZONE_NAME/home/$IRODS_USER_NAME/$REMOTE_USER"
REMOTE_USER="bobby#${P[zn]}"

su - irods -c "imkdir $REMOTE_USER_HOME"
su - irods -c "ichown write $REMOTE_USER $REMOTE_USER_HOME"

