#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../helper/functions.sh
source ${DIR}/../env.sh

poststart_checks
