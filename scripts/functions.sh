#!/bin/bash
retry() {
    local -r -i max_attempts="$1"; shift
    local -r -i sleep_interval="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1
 
    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Failed after $attempt_num attempts"
            return 1
        else
            printf "."
            ((attempt_num++))
            sleep $sleep_interval
        fi
    done
    printf "\n"
}

container_healthy() {
    local name=$1
    local container=$(docker-compose  ps -q $1)
    local healthy=$(docker inspect --format '{{ .State.Health.Status }}' $container)
    if [ $healthy == healthy ]
    then
        printf "$1 is healthy"
        return 0
    else
        return 1
    fi
}

verify_installed()
{
  local cmd="$1"
  if [[ $(type $cmd 2>&1) =~ "not found" ]]; then
    echo -e "\nERROR: This script requires '$cmd'. Please install '$cmd' and run again.\n"
    exit 1
  fi
}


mds_login()
{
  MDS_URL=$1
  SUPER_USER=$2
  SUPER_USER_PASSWORD=$3

  # Log into MDS
  if [[ $(type expect 2>&1) =~ "not found" ]]; then
    echo "'expect' is not found. Install 'expect' and try again"
    exit 1
  fi
  echo -e "\n# Login"
  OUTPUT=$(
  expect <<END
    log_user 1
    spawn confluent login --url $MDS_URL
    expect "Username: "
    send "${SUPER_USER}\r";
    expect "Password: "
    send "${SUPER_USER_PASSWORD}\r";
    expect "Logged in as "
    set result $expect_out(buffer)
END
  )
  echo "$OUTPUT"
  if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
    echo "Failed to log into your Metadata Server.  Please check all parameters and run again"
    exit 1
  fi
}
