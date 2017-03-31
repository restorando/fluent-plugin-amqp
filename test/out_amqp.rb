require 'test/unit'
require 'mocha/setup'

require 'fluent/test'
require 'fluent/plugin/out_amqp'

class AmqpOutputTest < Test::Unit::TestCase

  def setup
    require 'bunny'
    require 'yajl'
    Fluent::Test.setup
  end

  CONFIG = %[
    host localhost
    port 3333
    user test
    password test
    vhost /test
    exchange test-exchange
    exchange_type topic
    buffert_type memory
  ]

  PRIORITYCONFIG = %[
    host localhost
    port 3333
    user test
    password test
    vhost /test
    exchange test-exchange
    exchange_type topic
    priority 3
    buffert_type memory
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::AmqpOutput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal "localhost", d.instance.host
    assert_equal 3333, d.instance.port
    assert_equal "test", d.instance.user
    assert_equal "test", d.instance.password
    assert_equal "/test", d.instance.vhost
    assert_equal "test-exchange", d.instance.exchange
    assert_equal "topic", d.instance.exchange_type
  end

  def test_configure_with_priority
    d = create_driver PRIORITYCONFIG
    assert_equal "localhost", d.instance.host
    assert_equal 3333, d.instance.port
    assert_equal "test", d.instance.user
    assert_equal "test", d.instance.password
    assert_equal "/test", d.instance.vhost
    assert_equal "test-exchange", d.instance.exchange
    assert_equal "topic", d.instance.exchange_type
    assert_equal 3, d.instance.priority
  end

  def test_start_and_shutdown
    d = create_driver

    amqp_conn_mock = mock()
    amqp_exchange_mock = mock()
    Bunny.stubs(:new).returns(amqp_conn_mock)

    amqp_conn_mock.stubs(:open?).returns(false)
    amqp_conn_mock.expects(:start)
    amqp_conn_mock.expects(:stop)

    amqp_conn_mock.expects(:create_channel)
    Bunny::Exchange.expects(:new).returns(amqp_exchange_mock)

    d.instance.start
    # wait until thread starts
    10.times { sleep 0.05 }
    d.instance.shutdown
  end

  def test_flush
    d = create_driver

    amqp_conn_mock = mock()
    amqp_exchange_mock = mock()
    Bunny.stubs(:new).returns(amqp_conn_mock)
    amqp_conn_mock.stubs(:open?).returns(true)
    amqp_conn_mock.stubs(:create_channel)
    amqp_conn_mock.stubs(:stop)
    Bunny::Exchange.stubs(:new).returns(amqp_exchange_mock)

    t = Time.now.to_i
    d.emit({"a" => 1}, t)
    d.emit({"a" => 2}, t)

    ev1 = Yajl.dump({"key" => "test", "timestamp" => t, "payload" => {"a"=>1}})
    ev2 = Yajl.dump({"key" => "test", "timestamp" => t, "payload" => {"a"=>2}})
    amqp_exchange_mock.expects(:publish).with(ev1, { routing_key: "test", content_type: 'application/octet-stream' })
    amqp_exchange_mock.expects(:publish).with(ev2, { routing_key: "test", content_type: 'application/octet-stream' })

    d.run
  end

  def test_flush_with_priority
    d = create_driver PRIORITYCONFIG

    amqp_conn_mock = mock()
    amqp_exchange_mock = mock()
    Bunny.stubs(:new).returns(amqp_conn_mock)
    amqp_conn_mock.stubs(:open?).returns(true)
    amqp_conn_mock.stubs(:create_channel)
    amqp_conn_mock.stubs(:stop)
    Bunny::Exchange.stubs(:new).returns(amqp_exchange_mock)

    t = Time.now.to_i
    d.emit({"a" => 1}, t)

    ev1 = Yajl.dump({"key" => "test", "timestamp" => t, "payload" => {"a"=>1}})
    amqp_exchange_mock.expects(:publish).with(ev1, { routing_key: "test", content_type: 'application/octet-stream', priority: 3 })

    d.run
  end

end

