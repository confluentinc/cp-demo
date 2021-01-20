.. _cp-demo-teardown:
      
Teardown
========

Module 1: On-prem
-----------------

#. Stop the consumer group ``app`` to stop consuming from topic
   ``wikipedia.parsed``. Note that the command below stops the consumers
   gracefully with ``kill -15``, so the consumers follow the shutdown
   sequence.

   .. code:: bash

         ./scripts/app/stop_consumer_app_group_graceful.sh

#. Stop the Docker environment, destroy all components and clear all Docker
   volumes.

   .. sourcecode:: bash

          ./scripts/stop.sh


.. _cp-demo-ccloud-cleanup:

Module 2: |ccloud|
------------------

If you ran the :ref:`cp-demo-hybrid` portion of this tutorial, which included creating resources in |ccloud|, follow the clean up procedure below to avoid unexpected |ccloud| charges.

.. include:: ../../examples/ccloud/docs/includes/ccloud-examples-terminate.rst

#. If the on-prem cluster is still running, remove the |crep| connector that was replicating data to |ccloud|.

   .. code-block:: text

      docker-compose exec connect curl -X DELETE \
        --cert /etc/kafka/secrets/connect.certificate.pem \
        --key /etc/kafka/secrets/connect.key \
        --tlsv1.2 \
        --cacert /etc/kafka/secrets/snakeoil-ca-1.crt \
        -u connectorSubmitter:connectorSubmitter \
        https://connect:8083/connectors/replicate-topic-to-ccloud

#. If the on-prem cluster is still running, disable Telemetry Reporter in both |ak| brokers.

   .. code-block:: text

      docker-compose exec kafka1 kafka-configs \
        --bootstrap-server kafka1:12091 \
        --alter \
        --entity-type brokers \
        --entity-default \
        --delete-config confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret

#. Delete the ``Cloud`` API key.

   .. code-block:: text

      ccloud api-key delete ${METRICS_API_KEY}

#. Destroy your |ccloud| environment. Even if you stop ``cp-demo``, the resources in |ccloud| continue to incur charges until you destroy all the resources.

   .. code-block:: text

      source ./ccloud_library.sh
      source delta_configs/env.delta
      ccloud::destroy_ccloud_stack $SERVICE_ACCOUNT_ID

#. Log into `Confluent Cloud <https://confluent.cloud>`__ UI and verify all your resources have been destroyed.
