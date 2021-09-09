#!/bin/bash +x

SOURCE_TAG=${SOURCE_TAG:-7.0.x-latest-ubi8}
TARGET_TAG=${TARGET_TAG:-7.0.x-latest}

echo "Source Tag: ${SOURCE_TAG}"
echo "Target Tag: ${TARGET_TAG}"

# aws version note:sc
# If you're running an older version of the aws CLi you may need to change this command, for example:
# aws ecr getlogin --no-include-email --region us-west-2 --profile <profile-name> | docker login --username AWS --password-stdin 368821881613.dkr.ecr.us-west-2.amazonaws.com
# Per aws docs get-login is deprecated: https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login-password.html & https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login.html
aws ecr get-login-password | docker login --username AWS --password-stdin 368821881613.dkr.ecr.us-west-2.amazonaws.com

declare -a NAMES=("cp-zookeeper" "cp-enterprise-kafka" "cp-schema-registry" \
                  "cp-enterprise-control-center" "cp-enterprise-replicator" \
                  "cp-ksqldb-server" "cp-ksqldb-cli" "cp-kafka-connect" "cp-kafka-rest" \
                  "kafka-streams-examples" "ksqldb-examples" "cp-kafka" "cp-server" \
                  "cp-server-connect" "cp-server-connect-base")

NAMESPACE=confluentinc
REGISTRY=368821881613.dkr.ecr.us-west-2.amazonaws.com

for NAME in "${NAMES[@]}"
do
    docker image pull ${REGISTRY}/${NAMESPACE}/${NAME}:${SOURCE_TAG}
    docker image tag  ${REGISTRY}/${NAMESPACE}/${NAME}:${SOURCE_TAG} ${NAMESPACE}/${NAME}:${TARGET_TAG}
done