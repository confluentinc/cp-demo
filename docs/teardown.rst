.. _cp-demo-teardown:
      
Teardown
========

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

#. If you ran the :ref:`cp-demo-hybrid` portion of this tutorial, which included creating resources in |ccloud|, follow the clean up procedure in :ref:`cp-demo-ccloud-cleanup` to avoid unexpected |ccloud| charges.
