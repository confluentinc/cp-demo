#
# Copyright 2020 Confluent Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG REPOSITORY
ARG CP_VERSION

FROM $REPOSITORY/cp-enterprise-replicator:$CP_VERSION

ENV CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"

# Install SSE connector
RUN confluent-hub install --no-prompt cjmatta/kafka-connect-sse:1.0

# Install FromJson transformation
RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-json-schema:0.2.5

# Install Elasticsearch connector
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.0.0

# Add JDK default cacerts to kafka.connect.truststore.jks to allow outgoing HTTPS
COPY scripts/security/kafka.connect.truststore.jks /tmp/kafka.connect.truststore.jks
USER root
RUN keytool -importkeystore -srckeystore /usr/lib/jvm/zulu11-ca/lib/security/cacerts -srcstorepass changeit -destkeystore /tmp/kafka.connect.truststore.jks -deststorepass confluent -keypass confluent
USER appuser
