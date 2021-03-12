#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/helper/functions.sh
source ${DIR}/env.sh

#-------------------------------------------------------------------------------

echo "Killing broker kafka3, then tailing SBC logging output.  SBC will commence healing after about 30 seconds.  Type CTRL-C to stop tailing logs."
docker stop kafka3
docker-compose logs -f --tail=1000 | grep -E "(databalancer|cruisecontrol)" | grep -v "confluent.balancer.class"
