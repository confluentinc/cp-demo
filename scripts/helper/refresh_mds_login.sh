#!/bin/bash

################################## SETUP VARIABLES #############################
MDS_URL=http://kafka1:8091

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser

docker-compose exec tools bash -c ". /tmp/helper/functions.sh ; mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD}"