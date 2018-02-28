#!/bin/bash

COUCHBASE_HOST=localhost

if [[ $1 ]];then
    COUCHBASE_HOST=$1
fi

HEADER="Content-Type: application/x-www-form-urlencoded"
DATA="name=Kafka Connect&roles=cluster_admin&password=password"
UNAME=Administrator
PWORD=password

curl -X PUT --data "${DATA}" -H "${HEADER}" http://${UNAME}:${PWORD}@${COUCHBASE_HOST}:8091/settings/rbac/users/local/kafka-connect

