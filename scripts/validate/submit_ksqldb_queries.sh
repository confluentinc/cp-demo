while read ksqlCmd; do

  echo -e "\n$ksqlCmd\n"
  curl -X POST $KSQLDB_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQLDB_BASIC_AUTH_USER_INFO \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": '"ksql.streams.auto.offset.reset":"earliest","ksql.streams.cache.max.bytes.buffering":"0"'
}
EOF
)

done <statements.sql
