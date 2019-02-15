#!/usr/bin/env python

#########################
#
# Note: for demo purposes only, not for production
#
# Usage
# -----
#
# 1. Consume data from the '_confluent-monitoring' topic for 2 minutes
#    (assuming Confluent Monitoring Interceptors are configured on all clients)
#
#    docker-compose exec control-center \
#           /usr/bin/control-center-console-consumer \
#           /etc/confluent-control-center/control-center.properties \
#           --topic _confluent-monitoring \
#           --consumer.config /etc/kafka/secrets/client_without_interceptors.config
#
# 2. Save data to file called output.txt
#
# 3. Run this script
#
#    ./topic_client_map.py
#
#
#
# Sample output
# -------------
#
# WIKIPEDIABOT:
# - producers:
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-053e85c1-b4f0-4d17-a412-1ca2f9b8043a-StreamThread-7-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-053e85c1-b4f0-4d17-a412-1ca2f9b8043a-StreamThread-8-producer
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1-053e85c1-b4f0-4d17-a412-1ca2f9b8043a-StreamThread-6-producer
# - consumers:
#     connect-elasticsearch-ksql
#
# wikipedia.parsed:
# - producers:
#     producer-6
# - consumers:
#     _confluent-ksql-default_query_CSAS_WIKIPEDIABOT_1
#     _confluent-ksql-default_query_CTAS_EN_WIKIPEDIA_GT_1_2
#     connect-replicator
#     _confluent-ksql-default_query_CSAS_WIKIPEDIANOBOT_0
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
