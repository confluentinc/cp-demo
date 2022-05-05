# log in to confluent cloud
confluent login --save

# use ccloud environment
confluent environment list -o json | jq -r '.[] | select(.name=="chuck") | .id' | xargs confluent environment use

# use dedicated kafka cluster
confluent kafka cluster list -o json | jq -r '.[] | select(.name | contains("cp-demo")) | .id' | xargs confluent kafka cluster use

# Get CP Cluster ID
export CP_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ./scripts/security/snakeoil-ca-1.crt | jq -r ".id")

# export ccloud cluster id
export CC_CLUSTER_ID=$(confluent kafka cluster describe -o json | jq -r '.id')

# Name the cluster link
export CLUSTER_LINK_NAME=cp-cc-cluster-link

# Get bootstrap server endpoint
export CC_BOOTSTRAP_ENDPOINT=$(confluent kafka cluster describe -o json | jq -r .endpoint)

# create service account for the link
confluent iam service-account create cp-demo-cluster-link --description "service account for cp demo cluster link"
# create api key for cluster link service account
confluent api-key create --resource $CC_CLUSTER_ID --service-account $CC_SERVICE_ACCOUNT --description "cp demo cluster link"
# give service account alter acl on cluster
confluent kafka acl create --allow --service-account $CC_SERVICE_ACCOUNT --operation ALTER --cluster-scope  --cluster $CC_CLUSTER_ID
confluent kafka acl list

# get service account id
export CC_SERVICE_ACCOUNT=$(confluent iam service-account list -o json | jq -r '.[] | select(.name | contains("cp-demo")) | .id')


# Create cc half of link, must re-create with each new run of cp demo
confluent kafka link create $CLUSTER_LINK_NAME \
  --cluster $CC_CLUSTER_ID \
  --source-cluster-id $CP_CLUSTER_ID \
  --config-file ./scripts/ccloud/cluster-link-ccloud.properties \
  --source-bootstrap-server 0.0.0.0

confluent kafka link list --cluster $CC_CLUSTER_ID

confluent kafka link describe $CLUSTER_LINK_NAME --cluster $CC_CLUSTER_ID


# Create ccloud context for easy switching
confluent context update --name ccloud

# log in as superUser
confluent login --save --url https://localhost:8091 --ca-cert-path scripts/security/snakeoil-ca-1.crt

# Create cp context for easy switching
confluent context update --name cp

## TODO - need to give connectorSA (or new cluster-link-SA) principal ClusterAdmin
## (lower? DeveloperRead and DeveloperManage on topic?)
## permission on CP cluster to successfully describeTopics.
confluent iam rbac role-binding create \
  --principal User:connectorSA \
  --role DeveloperManage \
  --kafka-cluster-id $CP_CLUSTER_ID \
  --resource Topic:wikipedia --prefix


# Create the cp half of link
confluent kafka link create $CLUSTER_LINK_NAME \
  --destination-bootstrap-server $CC_BOOTSTRAP_ENDPOINT \
  --destination-cluster-id $CC_CLUSTER_ID \
  --config-file ./scripts/ccloud/cluster-link-cp.properties \
  --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt

confluent kafka link list --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt

confluent context use ccloud

confluent kafka mirror create wikipedia.parsed.count-by-domain --link $CLUSTER_LINK_NAME

# TODO what about schemas? they aren't coming along for the ride.
# Use schema linking: https://docs.confluent.io/cloud/current/sr/schema-linking.html


# teardown

# delete mirror topics
confluent kafka topic delete wikipedia.failed                  
confluent kafka topic delete wikipedia.parsed
confluent kafka topic delete wikipedia.parsed.count-by-domain

# Delete cluster link
confluent kafka link delete $CLUSTER_LINK_NAME

# Destroy CP cluster with stop.sh scrip