.. _cp-demo-hybrid:

Module 2: Hybrid Deployment to |ccloud| Tutorial
================================================

=============================
Hybrid Deployment to |ccloud|
=============================

In a hybrid |ak-tm| deployment scenario, you can have both an on-prem Confluent Platform deployment as well as a
`Confluent Cloud <https://confluent.cloud>`__ deployment.
In this module, you will use `Cluster Linking <https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/index.html>`__
and `Schema Linking <https://docs.confluent.io/platform/current/schema-registry/schema-linking-cp.html>`__ to send data and schemas to
|ccloud|, and monitor both deployments with the `Confluent Cloud Metrics API <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html>`__.

.. figure:: images/cp-demo-overview-with-ccloud.svg
    :alt: image

Before you begin this module, make sure the cp-demo ``start.sh`` script successfully completed with Confluent Platform already running :ref:`(see the on-prem module) <cp-demo-run>`.


Cost to Run
-----------

Caution
~~~~~~~

.. include:: ../../examples/ccloud/docs/includes/ccloud-examples-caution.rst

|ccloud| Promo Code
~~~~~~~~~~~~~~~~~~~

To receive an additional $50 free usage in |ccloud|, enter promo code ``CPDEMO50`` in the |ccloud| Console's `Billing and payment` section (`details <https://www.confluent.io/confluent-cloud-promo-disclaimer>`__).
This promo code should sufficiently cover up to one day of running this |ccloud| example, beyond which you may be billed for the services that have an hourly charge until you destroy the |ccloud| resources created by this example.


.. _cp-demo-setup-ccloud:

Setup |ccloud| and CLI
----------------------

#. Create a |ccloud| account at https://confluent.cloud.

#. Enter the promo code ``CPDEMO50`` in the |ccloud| UI `Billing and payment` section to receive an additional $50 free usage.

#. Create a "Dedicated" |ccloud| cluster (cluster linking requires a dedicated cluster).

#. Install `Confluent CLI <https://docs.confluent.io/confluent-cli/current/install.html>`__ v2.13.3 or later.

#. Using the CLI, log in to |ccloud| with the command ``confluent login``, and use your |ccloud| username and password. The ``--save`` argument saves your |ccloud| user login credentials or refresh token (in the case of SSO) to the local ``netrc`` file.

   .. code:: shell

      confluent login --save

.. #. The remainder of the |ccloud| portion of this tutorial must be completed sequentially. We recommend that you manually complete all the steps in the following sections. However, you may also run the script :devx-cp-demo:`scripts/ccloud/create-ccloud-workflow.sh|scripts/ccloud/create-ccloud-workflow.sh` which automates those steps. This option is recommended for users who have run this tutorial before and want to quickly bring it up.

..    .. code-block:: text

..       ./scripts/ccloud/create-ccloud-workflow.sh

.. _cp-demo-ccloud-stack:


.. ccloud-stack
.. ------------

.. Use the :ref:`ccloud-stack` for a quick, automated way to create resources in |ccloud|.  Executed with a single command, it uses the |ccloud| CLI to:

.. -  Create a new environment.
.. -  Create a new service account.
.. -  Create a new Kafka cluster and associated credentials.
.. -  Enable |sr-ccloud| and associated credentials.
.. -  Create ACLs with a wildcard for the service account.
.. -  Create a new ksqlDB app and associated credentials
.. -  Generate a local configuration file with all above connection information.

.. #. Get a bash library of useful functions for interacting with |ccloud| (one of which is ``cloud-stack``). This library is community-supported and not supported by Confluent.

..    .. code-block:: text

..       curl -sS -o ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh

.. #. Using ``ccloud_library.sh`` which you downloaded in the previous step, create a new ``ccloud-stack`` (see :ref:`ccloud-stack` for advanced options). It creates real resources in |ccloud| and takes a few minutes to complete.

..    .. note:: The ``true`` flag adds creation of a ksqlDB application in |ccloud|, which has hourly charges even if you are not actively using it.

..    .. code-block:: text

..       source ./ccloud_library.sh
..       export EXAMPLE="cp-demo" && ccloud::create_ccloud_stack true
 
.. #. When ``ccloud-stack`` completes, view the local configuration file at ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config`` that was auto-generated. It contains connection information for connecting to your newly created |ccloud| environment.

..    .. code-block:: text

..       cat stack-configs/java-service-account-*.config

.. #. In the current shell, set the environment variable ``SERVICE_ACCOUNT_ID`` to the <SERVICE_ACCOUNT_ID> in the filename. For example, if the filename is called ``stack-configs/java-service-account-154143.config``, then set ``SERVICE_ACCOUNT_ID=154143``. This environment variable is used later in the tutorial.

..    .. code-block:: text

..       SERVICE_ACCOUNT_ID=<fill in>

.. #. The |crep| :devx-cp-demo:`configuration file|scripts/connectors/submit_replicator_to_ccloud_config.sh` has parameters that specify how to connect to |ccloud|.  You could set these parameters manually, but to do this in an automated fashion, use another function to set env parameters customized for the |ccloud| instance created above. It reads your local |ccloud| configuration file, i.e., the auto-generated ``stack-configs/java-service-account-<SERVICE_ACCOUNT_ID>.config``, and creates files useful for |cp| components and clients connecting to |ccloud|.  Using ``ccloud_library.sh`` which you downloaded in an earlier step, run the ``generate_configs`` function against your auto-generated configuration file (the file created by ``ccloud-stack``).

..    .. code-block:: text

..       ccloud::generate_configs stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config

.. #. The output of the script is a folder called ``delta_configs`` with sample configurations for all components and clients, which you can easily apply to any |ak| client or |cp| component. View the ``delta_configs/env.delta`` file.

..    .. code-block:: text

..       cat delta_configs/env.delta

.. #. Source the ``delta_configs/env.delta`` file into your environment. These environment variables will be used in a few sections when you run |crep| to copy data from your on-prem cluster to your |ccloud| cluster.

..    .. code-block:: text

..       source delta_configs/env.delta




Export Schemas to |ccloud| with Schema Linking
----------------------------------------------

Send Data to |ccloud| with Cluster Linking
------------------------------------------

.. _cp-demo-metrics-api:

Metrics API
-----------

.. include:: includes/metrics-api-intro.rst

.. _cp-demo-telemetry-reporter:

Configure Confluent Health+ with the Telemetry Reporter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


.. _cp-demo-query-metrics:

Query Metrics
~~~~~~~~~~~~~

#. To define the time interval when querying the Metrics API, get the current time minus 1 hour and current time plus 1 hour. The ``date`` utility varies between operating systems, so use the ``tools`` Docker container to get consistent and reliable dates.

   .. code-block:: text

      CURRENT_TIME_MINUS_1HR=$(docker exec tools date -Is -d '-1 hour' | tr -d '\r')
      CURRENT_TIME_PLUS_1HR=$(docker exec tools date -Is -d '+1 hour' | tr -d '\r')

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

#. Your output should resemble the output below, showing metrics for the |ccloud| mirror topic ``wikipedia.parsed``:

   .. code-block:: text

      {
        "data": [
          {
            "timestamp": "2020-12-14T20:00:00Z",
            "value": 1690522,
            "metric.topic": "wikipedia.parsed"
          }
        ]
      }

.. _cp-demo-ccloud-ksqldb:

|ccloud| ksqlDB
---------------

This section shows how to create queries in the |ccloud| ksqlDB application that processes data from the ``wikipedia.parsed`` topic that the cluster link is mirroring from the on-prem cluster.

#. Create a ksqlDB cluster in your Confluent Cloud cluster. You can use the same "cloud" API key we used earlier to access the Metrics API. This will create a ksqlDB cluster with 1 CSU of processing power.

   .. code-block:: text

      confluent ksql cluster create \
         my-demo-ksql \
         --api-key $METRICS_API_KEY \
         --api-secret $METRICS_API_SECRET \
         --cluster $CCLOUD_CLUSTER_ID \
         --csu 1


#. Get the |ccloud| ksqlDB cluster ID and endpoint and save them to the parameters ``ksqlDBAppId`` and ``KSQLDB_ENDPOINT``.

   .. code-block:: text

      KSQL_INFO=$(confluent ksql cluster list -o json | jq '.[] | select(.name=="my-demo-ksql")')
      ksqlDBAppId=$(echo $KSQL_INFO | jq -r '.id')
      KSQLDB_ENDPOINT=$(echo $KSQL_INFO | jq -r '.endpoint')

#. Verify the |ccloud| ksqlDB application has transitioned from ``PROVISIONING`` to ``UP`` state. This may take a few minutes.

   .. code-block:: text

      confluent ksql cluster describe $ksqlDBAppId -o json

#. Configure ksqlDB ACLs to permit the ksqlDB application to read from ``wikipedia.parsed``.

   .. code-block:: text

      confluent ksql cluster configure-acls $ksqlDBAppId wikipedia.parsed

#. Create new ksqlDB queries in |ccloud| from the :devx-cp-demo:`scripts/ccloud/statements.sql|scripts/ccloud/statements.sql` file. Note: depending on which folder you are in, you may need to modify the relative path to the ``statements.sql`` file.

   .. code-block:: text

       while read ksqlCmd; do
         echo -e "\n$ksqlCmd\n"
         curl -X POST $KSQLDB_ENDPOINT/ksql \
              -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
              -u $METRICS_API_KEY:$METRICS_API_SECRET \
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
