# fluent-plugin-cloudtrail
Fluentd input plugin for AWS CloudTrail

## Install

### RubyGems

```
$ gem install fluent-plugin-cloudtrail
```

### td-agent

```
$ td-agent-gem install fluent-plugin-cloudtrail
```

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

## IAM Policy

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:GetQueueUrl",
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage"
            ],
            "Resource": "arn:aws:sqs:us-east-1:123456789012:cloudtrail-sqs-queue-name",
            "Effect": "Allow",
            "Sid": "AllowReadSqs"
        },
        {
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::cloudtrail-bucket-name/*",
            "Effect": "Allow",
            "Sid": "AllowReadS3Objects"
        }
    ]
}
```

