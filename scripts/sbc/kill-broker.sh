#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SBCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${SBCDIR}/../helper/functions.sh
source ${SBCDIR}/../env.sh

#-------------------------------------------------------------------------------

echo "Killing broker kafka3, which will trigger Self Balancing Cluster healing after about 30 seconds"
docker stop kafka3

# verify SBC responds with
MAX_WAIT=120
echo "Waiting up to $MAX_WAIT seconds for SBC self-healing to start"
retry $MAX_WAIT ${SBCDIR}/validate_sbc_kill_broker_started.sh || exit 1
