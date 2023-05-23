# plugin based on https://github.com/restorando/fluent-plugin-amqp/tree/master
# altered to be more stable when (connection) errors occur.
# publish acknowledgement for rabbitmq have been enabled.
# 
# Copyright (c) 2013 Restorando
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
        # publishing goes on exchange level
        get_or_create_exchange.publish Yajl.dump(event), puboptions
  
        # here we should wait for confirmation of publication
        @amqp_channel.wait_for_confirms
      end
    end
  
    private
  
    def get_or_create_exchange
      get_or_create_connection
  
      unless @amqp_channel && @amqp_channel.open?
        get_or_create_channel
        @amqp_exchange = Bunny::Exchange.new(@amqp_channel, @exchange_type.to_sym, @exchange_name, durable: @exchange_durable, no_declare: @passive)
      end
  
      @amqp_exchange
    end
  
    def get_or_create_connection
      @amqp_conn ||= Bunny.new(host: @host, vhost: @vhost, port: @port,
                user: @user, password: @password, threaded: false, automatically_recover: false)
      @amqp_conn.start unless @amqp_conn.open?
  
      @amqp_conn
    end
  
    def get_or_create_channel
  
      @amqp_channel  = @amqp_conn.create_channel
      @amqp_channel.confirm_select # enables publisher confirms
  
      @amqp_channel
    end
  
  end

end