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


#. Delete the ``Cloud`` API key you created to access the Metrics API.

   .. code-block:: text

      confluent api-key delete ${METRICS_API_KEY}

#. Delete the |ccloud| service account you created for the cluster link.

   .. code-block:: text

      confluent iam service-account delete ${SERVICE_ACCOUNT_ID}

#. Destroy your |ccloud| environment. Go to https://confluent.cloud/environments and delete the environment "cp-demo-env" that you created. This will destroy all clusters and resources associated with the environment.


#. If the on-prem cluster is still running, remove the cluster link that is mirroring data to |ccloud|.

   .. code-block:: text

      confluent kafka link delete $CLUSTER_LINK_NAME \
         --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt

#. If the on-prem cluster is still running, remove the schema exporter that is mirroring schemas to |ccloud|.

   .. code-block:: text

      confluent schema-registry exporter delete $SCHEMA_LINK_NAME \
         --url https://localhost:8091/kafka --ca-cert-path scripts/security/snakeoil-ca-1.crt


#. If the on-prem cluster is still running, disable Telemetry Reporter in both |ak| brokers.

   .. code-block:: text

      docker-compose exec kafka1 kafka-configs \
        --bootstrap-server kafka1:12091 \
        --alter \
        --entity-type brokers \
        --entity-default \
        --delete-config confluent.telemetry.enabled,confluent.telemetry.api.key,confluent.telemetry.api.secret

.. note::
   
   The Health+ cluster will be shown in the |ccloud| Console until it ages out.
