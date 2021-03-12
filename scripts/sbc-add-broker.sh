#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/env.sh

#-------------------------------------------------------------------------------

echo "Starting broker kafka3, then tailing SBC logging output.  Type CTRL-C to stop tailing logs."
docker-compose up -d kafka3
docker-compose logs -f --tail=1000 | grep -E "(databalancer|cruisecontrol)" | grep -v "confluent.balancer.class"
