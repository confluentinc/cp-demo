#!/bin/bash

input=/tmp/statements.sql
while IFS= read -r line
do
  echo -e "$line\nexit" | ksql -u ksqlDBUser -p ksqlDBUser http://ksqldb-server:8088
done < "$input"
