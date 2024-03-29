#!/bin/bash

su_replace() {
    test $# -lt 3 && { return 1; }
    local cmd file=$1 new=${2#.} old=${3#.}
    for cmd in "chown" "chmod"; do command $cmd --reference="$file" "$file.$new" ; done &&\
    mv $file{,.$old} &&\
    mv $file{.$new,}
}

irods_env_var() {
    su - ${2:-irods} -c "jq -r .'$1' ~/.irods/irods_environment.json"
}

[ -r /tmp/federate_with.txt ] || exit 1
typeset -A Remote=$(cat /tmp/federate_with.txt)

SERVER_CONFIG=/etc/irods/server_config.json

STATUS=-1
if [[ ! $(jq ".federation?" $SERVER_CONFIG) =~ ^\ *\[\ *\]\ *$ ]]; then
    echo >&2 "Federation config already set"
    exit 2
else
    EPOCH=`date +%s`
    jq '.federation+=[{
        "catalog_provider_hosts": ["'${Remote[hn]}'"],
        "negotiation_key": "'${Remote[nk]}'",
        "zone_key":  "'${Remote[zk]}'",
        "zone_name": "'${Remote[zn]}'",
        }]' $SERVER_CONFIG > $SERVER_CONFIG.new &&\
        su_replace $SERVER_CONFIG ".new" ".previous.$EPOCH"
        STATUS=$?
fi
echo "\$STATUS=${STATUS}"

su - irods -c '$HOME/irodsctl restart'

su - irods -c "iadmin mkzone ${Remote[zn]} remote ${Remote[hn]}:${Remote[zp]}"

su - irods -c "iadmin mkuser bobby rodsuser"
su - irods -c "iadmin moduser bobby password bpass"

IRODS_LOCAL_ZONE=$(irods_env_var irods_zone_name)

REMOTE_USER="bobby"

if [ -n "$REMOTE_USER" -a -n "${Remote[zn]}" ]
then
  REMOTE_USER="$REMOTE_USER#${Remote[zn]}"
  REMOTE_USER_HOME="/$IRODS_LOCAL_ZONE/home/$REMOTE_USER"
  su - irods -c "iadmin mkuser $REMOTE_USER rodsuser"
fi
