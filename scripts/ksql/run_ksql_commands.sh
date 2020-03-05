#!/bin/bash

input=/tmp/ksqlcommands
while IFS= read -r line
do
  echo -e "$line\nexit" | ksql -u ksqlSA -p ksqlSA http://ksql-server:8088
done < "$input"
