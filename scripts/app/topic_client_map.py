#!/usr/bin/env python

#########################
#
# Overview
# --------
# Dynamically map which producers are writing to which topics and which consumers are reading from which topics.
# Assumes Confluent Monitoring Interceptors are running.
#
# Note: for demo purposes only, not for production
#
# Usage
# -----
# ./topic_client_map.py
#
# Sample output
# -------------
#
# Reading topic _confluent-monitoring for 60 seconds...please wait
# 
# WIKIPEDIABOT:
# - producers:
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-d3bf43ec-0fb2-4919-9bed-d5941969dfbc-StreamThread-8-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-d3bf43ec-0fb2-4919-9bed-d5941969dfbc-StreamThread-6-producer
# - consumers:
#     connect-elasticsearch-ksql
# 
# wikipedia.parsed:
# - producers:
#     connect-worker-producer
# - consumers:
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
#     connect-replicator
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1
# 
# wikipedia.parsed.replica:
# - producers:
#     connect-worker-producer
# - consumers:
# 
# WIKIPEDIANOBOT:
# - producers:
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-f4141302-3f36-4c42-95ab-04012aa64be0-StreamThread-3-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-f4141302-3f36-4c42-95ab-04012aa64be0-StreamThread-4-producer
# - consumers:
#     WIKIPEDIANOBOT-consumer
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-repartition:
# - producers:
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-32cee64d-64dd-4fa9-b21b-e5bb7a0aed0a-StreamThread-12-producer
# - consumers:
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
# 
# EN_WIKIPEDIA_GT_1:
# - producers:
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-32cee64d-64dd-4fa9-b21b-e5bb7a0aed0a-StreamThread-9-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-32cee64d-64dd-4fa9-b21b-e5bb7a0aed0a-StreamThread-11-producer
# - consumers:
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-changelog:
# - producers:
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-32cee64d-64dd-4fa9-b21b-e5bb7a0aed0a-StreamThread-9-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-32cee64d-64dd-4fa9-b21b-e5bb7a0aed0a-StreamThread-11-producer
# - consumers:
# 
# EN_WIKIPEDIA_GT_1_COUNTS:
# - producers:
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-232a4aa1-f2cf-43a3-8c73-10b0410855da-StreamThread-13-producer
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-232a4aa1-f2cf-43a3-8c73-10b0410855da-StreamThread-15-producer
# - consumers:
#     EN_WIKIPEDIA_GT_1_COUNTS-consumer
#
#########################

import json
from collections import defaultdict
import subprocess
from threading import Timer

def get_output():
    """This function reads from the topic _confluent-monitoring
    for 60 seconds"""

    kill = lambda process: process.kill()

    command = "docker-compose exec control-center bash -c 'timeout 60 /usr/bin/control-center-console-consumer /etc/confluent-control-center/control-center.properties --topic _confluent-monitoring --consumer.config /etc/kafka/secrets/client_without_interceptors.config'"

    print "Reading topic _confluent-monitoring for 60 seconds...please wait"

    try:
        proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    except Exception as e:
        print e

    my_timer = Timer(1, kill, [proc])
    try:
        my_timer.start()
        stdout, stderr = proc.communicate()
    finally:
        my_timer.cancel()

    return stdout



topicMap = defaultdict(lambda: defaultdict(dict))

monitoringData = get_output()
for line in monitoringData.splitlines():
    
    try:
        a, b, c, d, e = line.strip().split("\t")
    except Exception as e:
        continue

    data = json.loads(e)

    topic = data["topic"]
    clientType = data["clientType"]
    clientId = data["clientId"]
    group = data["group"]

    if clientType == "PRODUCER":
        id = clientId
    else:
        id = group

    if clientType != "CONTROLCENTER":
        topicMap[topic][clientType][id] = 1


for topic in topicMap.keys():
    print "\n" + topic + ":"
    print "- producers:"
    producers = topicMap[topic]["PRODUCER"]
    for p in producers:
        print "    " + p
    print "- consumers:"
    consumers = topicMap[topic]["CONSUMER"]
    for c in consumers:
        print "    " + c
