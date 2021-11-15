.. _cp-demo-hybrid:

Module 2: Hybrid Deployment to |ccloud| Tutorial
================================================

=============================
Hybrid Deployment to |ccloud|
=============================

In a hybrid |ak-tm| deployment scenario, you can have both an on-prem and `Confluent Cloud <https://confluent.cloud>`__ deployment.
This part of the tutorial runs |crep| to send |ak| data to |ccloud|, and uses a common method, the `Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`__, for collecting metrics for both.

.. figure:: images/cp-demo-overview-with-ccloud.jpg
    :alt: image

Run this part of the tutorial only after you have completed the cp-demo :ref:`initial bring-up <cp-demo-run>`, because the initial bring-up deploys the on-prem cluster.
The steps in this section bring up the |ccloud| instance and interconnects it to your on-prem cluster.

Cost to Run
-----------

Caution
~~~~~~~

.. include:: ../../examples/ccloud/docs/includes/ccloud-examples-caution.rst

|ccloud| Promo Code
~~~~~~~~~~~~~~~~~~~

To receive an additional $50 free usage in |ccloud|, enter promo code ``CPDEMO50`` in the |ccloud| UI `Billing and payment` section (`details <https://www.confluent.io/confluent-cloud-promo-disclaimer>`__).
This promo code should sufficiently cover up to one day of running this |ccloud| example, beyond which you may be billed for the services that have an hourly charge until you destroy the |ccloud| resources created by this example.


.. _cp-demo-setup-ccloud:

Setup |ccloud| and CLI
----------------------

#. Create a |ccloud| account at https://confluent.cloud.

#. Setup a payment method for your |ccloud| account and optionally enter the promo code ``CPDEMO50`` in the |ccloud| UI `Billing and payment` section to receive an additional $50 free usage.

#. Install `Confluent CLI <https://docs.confluent.io/confluent-cli/current/install.html>`__ v2.0.0 or later.  Do not confuse this Confluent CLI binary v2 that is used to manage |ccloud| with the Confluent CLI binary v1 that is used to manage |cp| |release|.  See `documentation <https://docs.confluent.io/confluent-cli/current/migrate.html>`__ for more information on the CLI migration and running the CLIs in parallel.

#. Using the CLI, log in to |ccloud| with the command ``confluent login``, and use your |ccloud| username and password. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``netrc`` file.

   .. code:: shell

      confluent login --save

#. The remainder of the |ccloud| portion of this tutorial must be completed sequentially. We recommend that you manually complete all the steps in the following sections. However, you may also run the script :devx-cp-demo:`scripts/ccloud/create-ccloud-workflow.sh|scripts/ccloud/create-ccloud-workflow.sh` which automates those steps. This option is recommended for users who have run this tutorial before and want to quickly bring it up.

   .. code-block:: text

      ./scripts/ccloud/create-ccloud-workflow.sh

.. _cp-demo-ccloud-stack:

ccloud-stack
------------

Use the :ref:`ccloud-stack` for a quick, automated way to create resources in |ccloud|.  Executed with a single command, it uses the |ccloud| CLI to:

-  Create a new environment.
-  Create a new service account.
-  Create a new Kafka cluster and associated credentials.
-  Enable |sr-ccloud| and associated credentials.
-  Create ACLs with a wildcard for the service account.
-  Create a new ksqlDB app and associated credentials
-  Generate a local configuration file with all above connection information.

#. Get a bash library of useful functions for interacting with |ccloud| (one of which is ``cloud-stack``). This library is community-supported and not supported by Confluent.

   .. code-block:: text

      curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh

#. Using ``ccloud_library.sh`` which you downloaded in the previous step, create a new ``ccloud-stack`` (see :ref:`ccloud-stack` for advanced options). It creates real resources in |ccloud| and takes a few minutes to complete.

   .. note:: The ``true`` flag adds creation of a ksqlDB application in |ccloud|, which has hourly charges even if you are not actively using it.

   .. code-block:: text

      source ./ccloud_library.sh
      export EXAMPLE="cp-demo" && ccloud::create_ccloud_stack true
 
#. When ``ccloud-stack`` completes, view the local configuration file at ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config`` that was auto-generated. It contains connection information for connecting to your newly created |ccloud| environment.

   .. code-block:: text

      cat stack-configs/java-service-account-*.config

#. In the current shell, set the environment variable ``SERVICE_ACCOUNT_ID`` to the <SERVICE_ACCOUNT_ID> in the filename. For example, if the filename is called ``stack-configs/java-service-account-154143.config``, then set ``SERVICE_ACCOUNT_ID=154143``. This environment variable is used later in the tutorial.

   .. code-block:: text

      SERVICE_ACCOUNT_ID=<fill in>

#. The |crep| :devx-cp-demo:`configuration file|scripts/connectors/submit_replicator_to_ccloud_config.sh` has parameters that specify how to connect to |ccloud|.  You could set these parameters manually, but to do this in an automated fashion, use another function to set env parameters customized for the |ccloud| instance created above. It reads your local |ccloud| configuration file, i.e., the auto-generated ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config``, and creates files useful for |cp| components and clients connecting to |ccloud|.  Using ``ccloud_library.sh`` which you downloaded in an earlier step, run the ``generate_configs`` function against your auto-generated configuration file (the file created by ``ccloud-stack``).

   .. code-block:: text

      ccloud::generate_configs stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

#. The output of the script is a folder called ``delta_configs`` with sample configurations for all components and clients, which you can easily apply to any |ak| client or |cp| component. View the ``delta_configs/env.delta`` file.

   .. code-block:: text

      cat delta_configs/env.delta

#. Source the ``delta_configs/env.delta`` file into your environment. These environment variables will be used in a few sections when you run |crep| to copy data from your on-prem cluster to your |ccloud| cluster.

   .. code-block:: text

      source delta_configs/env.delta

.. _cp-demo-telemetry-reporter:

Telemetry Reporter
------------------

Enable :ref:`telemetry_reporter` on the on-prem cluster, and configure it to send metrics to the |ccloud| instance created above..

#. Create a new ``Cloud`` API key and secret to authenticate to |ccloud|. These credentials will be used to configure the Telemetry Reporter and used by the Metrics API.

   .. code:: shell

      confluent api-key create --resource cloud -o json

#. Verify your output resembles:

   .. code-block:: text

      {
         "key": "QX7X4VA4DFJTTOIA",
         "secret": "fjcDDyr0Nm84zZr77ku/AQqCKQOOmb35Ql68HQnb60VuU+xLKiu/n2UNQ0WYXp/D"
      }

   The value of the API key, in this case ``QX7X4VA4DFJTTOIA``, and API secret,
   in this case ``fjcDDyr0Nm84zZr77ku/AQqCKQOOmb35Ql68HQnb60VuU+xLKiu/n2UNQ0WYXp/D``,
   will differ in your output.

#. Set parameters to reference these credentials returned in the previous step.

   .. code-block:: text

      METRICS_API_KEY='QX7X4VA4DFJTTOIA'
      METRICS_API_SECRET='fjcDDyr0Nm84zZr77ku/AQqCKQOOmb35Ql68HQnb60VuU+xLKiu/n2UNQ0WYXp/D'

#. :ref:`Dynamically configure <kafka-dynamic-configurations>` the ``cp-demo`` cluster to use the Telemetry Reporter, which sends metrics to |ccloud|. This requires setting 3 configuration parameters: ``confluent.telemetry.enabled=true``, ``confluent.telemetry.api.key``, and ``confluent.telemetry.api.secret``.

   .. code-block:: text

      docker-compose exec kafka1 kafka-configs \
        --bootstrap-server kafka1:12091 \
        --alter \
        --entity-type brokers \
        --entity-default \
        --add-config confluent.telemetry.enabled=true,confluent.telemetry.api.key=${METRICS_API_KEY},confluent.telemetry.api.secret=${METRICS_API_SECRET}

#. Check the broker logs to verify the brokers were dynamically configured.

   .. sourcecode:: bash

      docker-compose logs kafka1 | grep confluent.telemetry.api

   Your output should resemble the following, but the ``confluent.telemetry.api.key`` value will be different in your environment.

   .. code-block:: text

      ...
      kafka1            | 	confluent.telemetry.api.key = QX7X4VA4DFJTTOIA
      kafka1            | 	confluent.telemetry.api.secret = [hidden]
      ...

#. Log into `Confluent Cloud <https://confluent.cloud>`__ UI and verify you see this cluster dashboard in the ``Hosted monitoring`` section under ``Confluent Platform``.

   .. figure:: images/hosted-monitoring.png


.. _cp-demo-replicator-to-ccloud:

|crep| to |ccloud|
------------------

Deploy |crep| to copy data from the on-prem cluster to the |ak| cluster running in |ccloud|.
It is configured to copy from the |ak| topic ``wikipedia.parsed`` (on-prem) to the cloud topic ``wikipedia.parsed.ccloud.replica`` in |ccloud|. 
The Replicator instance is running on the existing Connect worker in the on-prem cluster.

#. If you have been running ``cp-demo`` for a long time, you may need to refresh your local token to log back into MDS:

   .. sourcecode:: bash

      ./scripts/helper/refresh_mds_login.sh

#. Create a role binding to permit a new instance of |crep| to be submitted to the local connect cluster with id ``connect-cluster``.

   Get the |ak| cluster ID:

   .. literalinclude:: includes/get_kafka_cluster_id_from_host.sh

   Create the role bindings:

   .. code-block:: text

      docker-compose exec tools bash -c "confluent-v1 iam rolebinding create \
          --principal User:connectorSubmitter \
          --role ResourceOwner \
          --resource Connector:replicate-topic-to-ccloud \
          --kafka-cluster-id $KAFKA_CLUSTER_ID \
          --connect-cluster-id connect-cluster"

#. View the |crep| :devx-cp-demo:`configuration file|scripts/connectors/submit_replicator_to_ccloud_config.sh`. Note that it uses the local connect cluster (the origin site), so the |crep| configuration has overrides for the producer. The configuration parameters that use variables are read from the environment variables you sourced in an earlier step.

#. Submit the |crep| connector to the local connect cluster.

   .. code-block:: text

      ./scripts/connectors/submit_replicator_to_ccloud_config.sh

#. It takes about 1 minute to show up in the Connectors view in |c3|.  When it does, verify |crep| to |ccloud| has started properly, and there are now 4 connectors:

   .. figure:: images/connectors-with-rep-to-ccloud.png

#. Log into `Confluent Cloud <https://confluent.cloud>`__ UI and verify you see the topic ``wikipedia.parsed.ccloud.replica`` and its messages.

#. View the schema for this topic that is already registered in |ccloud| |sr|. In ``cp-demo``, in the :devx-cp-demo:`Replicator configuration file|scripts/connectors/submit_replicator_to_ccloud_config.sh`, ``value.converter`` is configured to use ``io.confluent.connect.avro.AvroConverter``, therefore it automatically registers new schemas, as needed, while copying data. The schema ID in the on-prem |sr| will not match the schema ID in the |ccloud| |sr|. (See documentation for other :ref:`schema migration options <schemaregistry_migrate>`)

   .. figure:: images/ccloud-schema.png

.. _cp-demo-metrics-api:

Metrics API
-----------

.. include:: includes/metrics-api-intro.rst

#. To define the time interval when querying the Metrics API, get the current time minus 1 hour and current time plus 1 hour. The ``date`` utility varies between operating systems, so use the ``tools`` Docker container to get consistent and reliable dates.

   .. code-block:: text

      CURRENT_TIME_MINUS_1HR=$(docker-compose exec tools date -Is -d '-1 hour' | tr -d '\r')
      CURRENT_TIME_PLUS_1HR=$(docker-compose exec tools date -Is -d '+1 hour' | tr -d '\r')

#. For the on-prem metrics: view the :devx-cp-demo:`metrics query file|scripts/ccloud/metrics_query_onprem.json`, which requests ``io.confluent.kafka.server/received_bytes`` for the topic ``wikipedia.parsed`` in the on-prem cluster (for all queryable metrics examples, see `Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`__).

   .. literalinclude:: ../scripts/ccloud/metrics_query_onprem.json

#. Substitute values into the query json file. For this substitution to work, you must have set the following parameters in your environment:

   - ``CURRENT_TIME_MINUS_1HR``
   - ``CURRENT_TIME_PLUS_1HR``

   .. code-block:: text

      DATA=$(eval "cat <<EOF
      $(<./scripts/ccloud/metrics_query_onprem.json)
      EOF
      ")

      # View this parameter
      echo $DATA

#. Send this query to the Metrics API endpoint at https://api.telemetry.confluent.cloud/v2/metrics/hosted-monitoring/query. For this query to work, you must have set the following parameters in your environment:

   - ``METRICS_API_KEY``
   - ``METRICS_API_SECRET``

   .. code-block:: text

      curl -s -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
           --header 'content-type: application/json' \
           --data "${DATA}" \
           https://api.telemetry.confluent.cloud/v2/metrics/hosted-monitoring/query \
              | jq .

#. Your output should resemble the output below, showing metrics for the on-prem topic ``wikipedia.parsed``:

   .. code-block:: text

      {
        "data": [
          {
            "timestamp": "2020-12-14T20:52:00Z",
            "value": 1744066,
            "metric.topic": "wikipedia.parsed"
          },
          {
            "timestamp": "2020-12-14T20:53:00Z",
            "value": 1847596,
            "metric.topic": "wikipedia.parsed"
          }
        ]
      }

#. For the |ccloud| metrics: view the :devx-cp-demo:`metrics query file|scripts/ccloud/metrics_query_ccloud.json`, which requests ``io.confluent.kafka.server/received_bytes`` for the topic ``wikipedia.parsed.ccloud.replica`` in |ccloud| (for all queryable metrics examples, see `Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`__).

   .. literalinclude:: ../scripts/ccloud/metrics_query_ccloud.json

#. Get the |ak| cluster ID in |ccloud|, derived from the ``$SERVICE_ACCOUNT_ID``.

   .. code-block:: text

      CCLOUD_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -c -r '.[] | select (.name == "'"demo-kafka-cluster-${SERVICE_ACCOUNT_ID}"'")' | jq -r .id)

#. Substitute values into the query json file. For this substitution to work, you must have set the following parameters in your environment:

   - ``CURRENT_TIME_MINUS_1HR``
   - ``CURRENT_TIME_PLUS_1HR``
   - ``CCLOUD_CLUSTER_ID``

   .. code-block:: text

      DATA=$(eval "cat <<EOF
      $(<./scripts/ccloud/metrics_query_ccloud.json)
      EOF
      ")

      # View this parameter
      echo $DATA

#. Send this query to the Metrics API endpoint at https://api.telemetry.confluent.cloud/v2/metrics/cloud/query. For this query to work, you must have set the following parameters in your environment:

   - ``METRICS_API_KEY``
   - ``METRICS_API_SECRET`` 

   .. code-block:: text

      curl -s -u ${METRICS_API_KEY}:${METRICS_API_SECRET} \
           --header 'content-type: application/json' \
           --data "${DATA}" \
           https://api.telemetry.confluent.cloud/v2/metrics/cloud/query \
              | jq .

#. Your output should resemble the output below, showing metrics for the |ccloud| topic ``wikipedia.parsed.ccloud.replica``:

   .. code-block:: text

      {
        "data": [
          {
            "timestamp": "2020-12-14T20:00:00Z",
            "value": 1690522,
            "metric.topic": "wikipedia.parsed.ccloud.replica"
          }
        ]
      }

.. _cp-demo-ccloud-ksqldb:

|ccloud| ksqlDB
---------------

This section shows how to create queries in the |ccloud| ksqlDB application that processes data from the ``wikipedia.parsed.ccloud.replica`` topic that |crep| copied from the on-prem cluster.
You must have completed :ref:`cp-demo-ccloud-stack` before proceeding.

#. Get the |ccloud| ksqlDB application ID and save it to the parameter ``ksqlDBAppId``.

   .. code-block:: text

      ksqlDBAppId=$(confluent ksql app list | grep "$KSQLDB_ENDPOINT" | awk '{print $1}')

#. Verify the |ccloud| ksqlDB application has transitioned from ``PROVISIONING`` to ``UP`` state. This may take a few minutes.

   .. code-block:: text

      confluent ksql app describe $ksqlDBAppId -o json

#. Configure ksqlDB ACLs to permit the ksqlDB application to read from ``wikipedia.parsed.ccloud.replica``.

   .. code-block:: text

      confluent ksql app configure-acls $ksqlDBAppId wikipedia.parsed.ccloud.replica

#. Create new ksqlDB queries in |ccloud| from the :devx-cp-demo:`scripts/ccloud/statements.sql|scripts/ccloud/statements.sql` file. Note: depending on which folder you are in, you may need to modify the relative path to the ``statements.sql`` file.

   .. code-block:: text

       while read ksqlCmd; do
         echo -e "\n$ksqlCmd\n"
         curl -X POST $KSQLDB_ENDPOINT/ksql \
              -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
              -u $KSQLDB_BASIC_AUTH_USER_INFO \
              --silent \
              -d @<(cat <<EOF
       {
         "ksql": "$ksqlCmd",
         "streamsProperties": {}
       }
       EOF
       )
       done <scripts/ccloud/statements.sql

#. Log into `Confluent Cloud <https://confluent.cloud>`__ UI and view the ksqlDB application Flow.

   .. figure:: images/ccloud_ksqldb_flow.png

#. View the events in the ksqlDB streams in |ccloud|.

   .. figure:: images/ccloud_ksqldb_stream.png

#. Go to :ref:`cp-demo-ccloud-cleanup` and destroy the demo resources used. Important: The ksqlDB application in |ccloud| has hourly charges even if you are not actively using it.


Cleanup
-------

.. include:: ../../examples/ccloud/docs/includes/ccloud-examples-terminate.rst

Follow the clean up procedure in :ref:`cp-demo-ccloud-cleanup` to avoid unexpected |ccloud| charges.
