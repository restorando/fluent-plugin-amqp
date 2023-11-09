# AMQP output plugin for Fluentd

Fluentd output plugin to publish events to an amqp broker.

Events are published one by one using the Fluentd tag as the routing key, in JSON format like:

```javascript
{ "key": "fluentd-tag", "timestamp": "fluentd-timestamp", "payload": "event-payload" }
```

## Testing

`docker compose exec -u {yourusename} ruby ruby test/out_amqp.rb`

## Installation

 This plugin should be installed from its Github repository. In order to do that, you need access to a Github user with read access to the repository.

```
$ export GITHUB_PACKAGE_USERNAME=user%40domain.com
$ export GITHUB_PACKAGE_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxx
$ fluent-gem  install --source https://$GITHUB_PACKAGE_USERNAME:$GITHUB_PACKAGE_TOKEN@rubygems.pkg.github.com/fonq/ fluent-plugin-amqp -V --version "0.2.2"
```

Be sure to URL encode any special characters in the environment variables. Specify the version of the package that is specified in the gemspec file. The exact name of the gem utility will vary depending on the fluentd or td-agent package you have installed, but it should be from the package, and not from Ruby itself.

## Configuration

```
<match pattern>
  type amqp

  # Set broker host and port
  host localhost
  port 5672

  # Set user and password for authentication
  user guest
  password guest

  # Configure amqp entities vhost, exchange id and type
  vhost /
  exchange my_exchange
  exchange_type topic
  exchange_durable true # optionally set exchange durability - default is true.
  passive false # If true, will not try to create the exchange - default is false.
  payload_only false # optional - default is false. if true, only the payload will be sent. if false, data format is { "key" => tag, "timestamp" => time, "payload" => record }.
  content_type application/octet-stream # optional - default is application/octet-stream. some amqp consumers will expect application/json.
  priority 0 # the priority for the message - requires bunny >= 1.1.6 and rabbitmq >= 3.5
</match>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
