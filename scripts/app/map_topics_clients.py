#!/usr/bin/env python

#########################
#
# Overview
# --------
# Dynamically map which producers are writing to which topics and which consumers are reading from which topics.
# Assumes Confluent Monitoring Interceptors are running.
#
# Note: for demo purposes only, not for production. Format of monitoring data subject to change
#
# Usage
# -----
# ./map_topics_clients.py
#
# Sample output
# -------------
#
# Reading topic _confluent-monitoring for 60 seconds...please wait
# 
# WIKIPEDIABOT
#   producers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-27512fbf-3272-4a50-a980-ed10cd554435-StreamThread-5-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-27512fbf-3272-4a50-a980-ed10cd554435-StreamThread-7-producer
#   consumers
#     connect-elasticsearch-ksql
# 
# wikipedia.parsed
#   producers
#     connect-worker-producer
#   consumers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
#     connect-replicator
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0
# 
# wikipedia.parsed.replica
#   producers
#     connect-worker-producer
# 
# WIKIPEDIANOBOT
#   producers
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-61e1a062-4e98-4793-a923-5a89c73b9b4e-StreamThread-3-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0-61e1a062-4e98-4793-a923-5a89c73b9b4e-StreamThread-4-producer
#   consumers
#     WIKIPEDIANOBOT-consumer
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-repartition
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-89f69ebe-0d29-4717-aafb-846945e5142e-StreamThread-12-producer
#   consumers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
# 
# EN_WIKIPEDIA_GT_1
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-89f69ebe-0d29-4717-aafb-846945e5142e-StreamThread-11-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-89f69ebe-0d29-4717-aafb-846945e5142e-StreamThread-9-producer
#   consumers
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3
# 
# _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-KSTREAM-AGGREGATE-STATE-STORE-0000000007-changelog
#   producers
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-89f69ebe-0d29-4717-aafb-846945e5142e-StreamThread-11-producer
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2-89f69ebe-0d29-4717-aafb-846945e5142e-StreamThread-9-producer
# 
# EN_WIKIPEDIA_GT_1_COUNTS
#   producers
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-2b6ddd23-7a97-4b0b-8094-f936aa539f1b-StreamThread-16-producer
#     _confluent-ksql-default_query_CSAS_EN_WIKIPEDIA_GT_1_COUNTS_3-2b6ddd23-7a97-4b0b-8094-f936aa539f1b-StreamThread-14-producer
#   consumers
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

    # 'timeout 60' should not be required but otherwise timer never kills the process 
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
    print "\n" + topic + ""
    producers = topicMap[topic]["PRODUCER"]
    if len(producers) > 0:
        print "  producers"
    for p in producers:
        print "    " + p
    consumers = topicMap[topic]["CONSUMER"]
    if len(consumers) > 0:
        print "  consumers"
    for c in consumers:
        print "    " + c
