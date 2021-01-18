You can use the Metrics API to get data for both the on-prem cluster as well as the |ccloud| cluster.
The Metrics API provides a queryable HTTP API in which you can post a query to get a time series of metrics.
It can be used for observing both:

- On-prem metrics (enabled by Telemetry Reporter) using the endpoint https://api.telemetry.confluent.cloud/v1/metrics/hosted-monitoring/query (this is in preview and the API may change)
- |ccloud| metrics using the endpoint https://api.telemetry.confluent.cloud/v1/metrics/cloud/query

.. figure:: images/metrics-api.jpg
