# Run commands in tools container so we have proper hostname networking to CP components
docker-compose exec tools /bin/bash

# Get CP Cluster ID
export CP_CLUSTER_ID=$(curl -s https://localhost:8091/v1/metadata/id --tlsv1.2 --cacert ./scripts/security/snakeoil-ca-1.crt | jq -r ".id")

# log in to confluent cloud
confluent login --save

# use ccloud environment
confluent environment list -o json | jq -r '.[] | select(.name=="chuck") | .id' | xargs confluent environment use

# use dedicated kafka cluster
confluent kafka cluster list -o json | jq -r '.[] | select(.name | contains("cp-demo")) | .id' | xargs confluent kafka cluster use

# export ccloud cluster id
export CC_CLUSTER_ID=$(confluent kafka cluster describe -o json | jq -r '.id')

# create service account for the link
confluent iam service-account create cp-demo-cluster-link --description "service account for cp demo cluster link"

# get service account id
export CC_SERVICE_ACCOUNT=$(confluent iam service-account list -o json | jq -r '.[] | select(.name | contains("cp-demo")) | .id')

# create api key for cluster link service account
confluent api-key create --resource $CC_CLUSTER_ID --service-account $CC_SERVICE_ACCOUNT --description "cp demo cluster link"

# give service account alter acl on cluster
confluent kafka acl create --allow --service-account $CC_SERVICE_ACCOUNT --operation ALTER --cluster-scope  --cluster $CC_CLUSTER_ID

confluent kafka acl list

export CLUSTER_LINK_NAME=cp-cc-cluster-link

# If you are re-running CP demo with a new cp cluster id
confluent kafka link delete $CLUSTER_LINK_NAME

# Create cc half of link, must re-create with each new run of cp demo
confluent kafka link create $CLUSTER_LINK_NAME \
  --cluster $CC_CLUSTER_ID \
  --source-cluster-id $CP_CLUSTER_ID \
  --config-file ./scripts/ccloud/cluster-link-ccloud.properties \
  --source-bootstrap-server 0.0.0.0

confluent kafka link list --cluster $CC_CLUSTER_ID

confluent kafka link describe $CLUSTER_LINK_NAME --cluster $CC_CLUSTER_ID

export CC_BOOTSTRAP_ENDPOINT=$(confluent kafka cluster describe -o json | jq -r .endpoint)

# Create ccloud context for easy switching
confluent context update --name ccloud

# log in as superUser
confluent login --url https://localhost:8091 --ca-cert-path scripts/security/snakeoil-ca-1.crt

# Create cp context for easy switching
confluent context update --name cp

## TODO - need to give connectorSA (or new cluster-link-SA) principal ClusterAdmin (lower?)
## permission on CP cluster to successfully describeTopics.


# Create the cp half of link
confluent kafka link create $CLUSTER_LINK_NAME \
  --destination-bootstrap-server $CC_BOOTSTRAP_ENDPOINT \
  --destination-cluster-id $CC_CLUSTER_ID \
  --config-file ./scripts/ccloud/cluster-link-cp.config \
  --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt

confluent kafka link list --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt

confluent context use ccloud

confluent kafka mirror create wikipedia.parsed.count-by-domain --link $CLUSTER_LINK_NAME

# TODO what about schemas? they aren't coming along for the ride.
