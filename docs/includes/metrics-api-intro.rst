The Confluent Cloud Metrics API is a REST API you can use to query timeseries metrics.
You can use the Metrics API to get telemetry data for both the on-prem Confluent Platform cluster as well as the |ccloud| cluster.

-   On-prem metrics (enabled by Telemetry Reporter) using the endpoint https://api.telemetry.confluent.cloud/v2/metrics/hosted-monitoring/query

   .. note:: The hosted monitoring endpoint is in preview and the endpont will eventually be renamed https://api.telemetry.confluent.cloud/v2/metrics/health-plus/query
  
- |ccloud| metrics using the endpoint https://api.telemetry.confluent.cloud/v2/metrics/cloud/query
- See the `Confluent Cloud Metrics API Reference <https://api.telemetry.confluent.cloud/docs>`__ for more information.


The Metrics API and Telemetry Reporter powers `Health+ <https://docs.confluent.io/platform/current/health-plus/index.html>`__, the fully-managed monitoring
solution for Confluent Platform. You can enable Health+ for free and add premium capabilities as you see fit.

Popular `third-party monitoring tools <https://docs.confluent.io/cloud/current/monitoring/metrics-api.html#integrate-with-third-party-monitoring>`__
like Datadog and Grafana Cloud integrate with the Metrics API out-of-the-box,
or if you manage your own Prometheus database, the Metrics API can also export metrics in Prometheus format.

.. figure:: images/metrics-api.svg
