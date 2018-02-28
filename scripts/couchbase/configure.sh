#!/bin/bash

COUCHBASE_HOST=localhost

if [[ $1 ]];then
    COUCHBASE_HOST=$1
fi

HEADER="Content-Type: application/x-www-form-urlencoded"
DATA="name=Kafka Connect&roles=cluster_admin&password=password"
UNAME=Administrator
PWORD=password

# Initialize Node
curl  -u ${UNAME}:${PWORD} -v -X POST http://${COUCHBASE_HOST}:8091/nodes/self/controller/settings \
  -d 'data_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata& \
  index_path=%2Fopt%2Fcouchbase%2Fvar%2Flib%2Fcouchbase%2Fdata'
        

# Rename Node
curl  -u ${UNAME}:${PWORD} -v -X POST http://${COUCHBASE_HOST}:8091/node/controller/rename \
  -d 'hostname=127.0.0.1'
        
# Setup Services
curl  -u ${UNAME}:${PWORD} -v -X POST http://${COUCHBASE_HOST}:8091/node/controller/setupServices \
  -d 'services=kv%2Cn1ql%2Cindex%2Cfts'
        
# Setup Administrator username and password
curl  -u ${UNAME}:${PWORD} -v -X POST http://${COUCHBASE_HOST}:8091/settings/web \
  -d 'password=password&username=Administrator&port=SAME'

# Set Memory Quotas
curl -X POST -u ${UNAME}:${PWORD} http://${COUCHBASE_HOST}:8091/pools/default \
  -d 'memoryQuota=256&indexMemoryQuota=256&ftsMemoryQuota=256' 
        
# Setup Bucket
curl  -u ${UNAME}:${PWORD} -v -X POST http://${COUCHBASE_HOST}:8091/pools/default/buckets \
  -d 'replicaNumber=0&ramQuotaMB=128&bucketType=membase&name=wikipedia'


#Create User for Kafka Connect
curl -X PUT --data "${DATA}" -H "${HEADER}" http://${UNAME}:${PWORD}@${COUCHBASE_HOST}:8091/settings/rbac/users/local/kafka-connect

