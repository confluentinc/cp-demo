#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../helper/functions.sh
source ${DIR}/../env.sh

#-------------------------------------------------------------------------------

(cd $DIR/security && ./certs-create-per-user.sh kafka3) || exit 1

docker-compose -f $DIR/../docker-compose.yml -f $DIR/sbc/docker-compose.yml up -d kafka3

# verify SBC responds with an add-broker balance plan
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for SBC add broker to start rebalance planning"
retry $MAX_WAIT ${DIR}/sbc/validate_sbc_add_broker_plan_computation.sh || exit 1
