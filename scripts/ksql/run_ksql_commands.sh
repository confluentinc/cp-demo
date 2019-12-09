#!/bin/bash

input=/tmp/ksqlcommands
while IFS= read -r line
do
  /tmp/run_ksql_cmd.sh "$line"
done < "$input"
