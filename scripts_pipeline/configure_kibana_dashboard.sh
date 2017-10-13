#!/bin/bash

curl -X PUT -H "kbn-version: 5.5.2" -d '{"title":"wikipedia.parsed","notExpandable":true}' http://localhost:5601/es_admin/.kibana/index-pattern/wikipedia.parsed/_create 
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"wikipedia.parsed"}' http://localhost:5601/api/kibana/settings/timelion:es.default_index
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"createdat"}' http://localhost:5601/api/kibana/settings/timelion:es.timefield
curl -X POST -H "kbn-version: 5.5.2" -H "Content-Type: application/json;charset=UTF-8" -d '{"value":"wikipedia.parsed"}' http://localhost:5601/api/kibana/settings/defaultIndex
#curl -X GET http://localhost:5601/api/kibana/dashboards/export?dashboard=Wikipedia > /tmp/dash.json
curl -X POST -H 'kbn-xsrf:true' -H 'Content-type:application/json' -d @scripts_pipeline/kibana_dash.json http://localhost:5601/api/kibana/dashboards/import

