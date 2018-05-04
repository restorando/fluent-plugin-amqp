module Fluent

class AmqpOutput < Fluent::BufferedOutput
  # First, register the plugin. NAME is the name of this plugin
  # and identifies the plugin in the configuration file.
  Fluent::Plugin.register_output('amqp', self)

  config_param :host, :string, default: "127.0.0.1"
  config_param :port, :integer, default: 5672
  config_param :user, :string, default: "guest"
  config_param :password, :string, default: "guest", :secret => true
  config_param :vhost, :string, default: "/"
  config_param :exchange, :string, default: ""
  config_param :exchange_type, :string, default: "topic"
  config_param :exchange_durable, :bool, default: true
  config_param :passive, :bool, default: false
  config_param :payload_only, :bool, default: false
  config_param :content_type, :string, default: "application/octet-stream"
  config_param :priority, :integer, default: nil

  def initialize(*)
    super
    require "bunny"
    require "yajl"
  end

  # This method is called before starting.
  # 'conf' is a Hash that includes configuration parameters.
  # If the configuration is invalid, raise Fluent::ConfigError.
  def configure(conf)
    super

    raise Fluent::ConfigError, "missing host infromation" unless @host
    raise Fluent::ConfigError, "missing exchange" unless @exchange

    @exchange_name = @exchange
  end

  # This method is called when starting.
  # Open sockets or files here.
  def start
    super

    begin
      get_or_create_exchange
    rescue => e
      $log.error "AMQP error", error: e.to_s
      $log.warn_backtrace e.backtrace
    end
  end

  # This method is called when shutting down.
  # Shutdown the thread and close sockets or files here.
  def shutdown
    super
    @amqp_conn && @amqp_conn.stop
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  # This method is called every flush interval. Write the buffer chunk
  # to files or databases here.
  # 'chunk' is a buffer chunk that includes multiple formatted
  # events. You can use 'data = chunk.read' to get all events and
  # 'chunk.open {|io| ... }' to get IO objects.
  def write(chunk)
    chunk.msgpack_each do |(tag, time, record)|
      event = @payload_only ? record : { "key" => tag, "timestamp" => time, "payload" => record }
      puboptions = { routing_key: tag, content_type: @content_type }
      if @priority
        puboptions[:priority] = @priority
      end
      get_or_create_exchange.publish Yajl.dump(event), puboptions
    end
  end

  private

  def get_or_create_exchange
    @amqp_conn ||= Bunny.new(host: @host, vhost: @vhost, port: @port,
      user: @user, password: @password, threaded: false, automatically_recover: false)

    @amqp_conn.start unless @amqp_conn.open?

    unless @amqp_channel && @amqp_channel.open?
      @amqp_channel  = @amqp_conn.create_channel
      @amqp_exchange = Bunny::Exchange.new(@amqp_channel, @exchange_type.to_sym, @exchange_name, durable: @exchange_durable, no_declare: @passive)
    end

    @amqp_exchange
  end

end

end
