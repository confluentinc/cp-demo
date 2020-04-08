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

FROM confluentinc/cp-server-connect:5.5.x-latest

ENV CONNECT_PLUGIN_PATH: "/usr/share/java,/connect-plugins"

# GA image posted on Confluent Hub
#RUN confluent-hub install --no-prompt confluentinc/kafka-connect-replicator:5.4.1

# Pre-GA image: requires access to pre-GA package of Confluent Replicator on local host
COPY confluentinc-kafka-connect-replicator-5.5.0-SNAPSHOT.zip /tmp/confluentinc-kafka-connect-replicator-5.5.0-SNAPSHOT.zip
RUN confluent-hub install --no-prompt /tmp/confluentinc-kafka-connect-replicator-5.5.0-SNAPSHOT.zip
