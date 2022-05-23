.. _cp-demo-teardown:
      
Teardown
========

Tear Down On-prem
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

Tear Down |ccloud|
------------------

If you ran the :ref:`cp-demo-hybrid` portion of this tutorial, which included creating resources in |ccloud|, follow the clean up procedure below to avoid unexpected |ccloud| charges.

.. include:: ../../examples/ccloud/docs/includes/ccloud-examples-terminate.rst

#. Make sure that you're still using the ``ccloud`` CLI context.

   .. code::

      confluent context use ccloud

#. Delete the |ccloud| service account you created for the cluster link. This will also delete all API keys associated with the account.

   .. code-block:: text

      confluent iam service-account delete ${SERVICE_ACCOUNT_ID}

#. Destroy your |ccloud| ksqlDB cluster. Go to https://confluent.cloud/environments -> Select **cp-demo-cluster** -> ksqlDB -> Select "delete".

#. Destroy your |ccloud| cluster. Go to https://confluent.cloud/environments -> Select **cp-demo-cluster** -> Cluster Overview -> Cluster Settings -> Select "Delete cluster".

#. Destroy your |ccloud| environment. Go to https://confluent.cloud/environments and delete the environment "cp-demo-env" that you created.


.. note::
   
   The Health+ cluster will be shown in the |ccloud| Console until it ages out.
