# fluent-plugin-cloudtrail
Fluentd input plugin for AWS CloudTrail

## Example config

```
# Get events from CloudTrail
<source>
  type cloudtrail
  sqs_url <SQS_URL>
  role_arn <ROLE_ARN>
  tag cloudtrail
</source>

# Filter CloudTrail logs
<filter cloudtrail>
  type grep
  regexp1 eventSource ^signin\.amazonaws\.com$
</filter>

# Store CloudTrail data in Elasticsearch
<match cloudtrail>
  @type copy
  <store>
    @type elasticsearch
    hosts https://<ELASTICSEARCH_DOMAIN_ENDPOINT>:443/
    type_name cloudtrail
    include_tag_key true
    tag_key @log_name
    logstash_format true
    flush_interval 10s
    time_key eventTime
  </store>
  <store>
    @type stdout
  </store>
</match>
```
