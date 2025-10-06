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

# Stage 1 -- install connectors
FROM $REPOSITORY/cp-server-connect:$CP_VERSION AS install-connectors

ENV CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"

# Install SSE connector
RUN confluent-hub install --no-prompt cjmatta/kafka-connect-sse:1.0

# Install FromJson transformation
RUN confluent-hub install --no-prompt jcustenborder/kafka-connect-json-schema:0.2.5

# Install Elasticsearch connector
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:15.0.0


# Stage 2 -- copy jars
FROM $REPOSITORY/cp-server-connect:$CP_VERSION

COPY --from=install-connectors /usr/share/confluent-hub-components/ /usr/share/confluent-hub-components/