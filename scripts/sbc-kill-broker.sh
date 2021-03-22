#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/env.sh

#-------------------------------------------------------------------------------

echo "Killing broker kafka3, which will trigger Self Balancing Cluster healing after about 30 seconds"
docker stop kafka3

# verify SBC responds with
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for SBC self-healing to start"
retry $MAX_WAIT $DIR/validate/validate_sbc_kill_broker.sh || exit 1
