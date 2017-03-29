require 'helper'

class MysqlQueryInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    host            localhost
    port            3306
    interval        30
    tag             input.mysql
    query           SHOW VARIABLES LIKE 'Thread_%'
    record_hostname yes
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::MysqlQueryInput).configure(conf)
  end

  sub_test_case "configure" do
    test "empty" do
      assert_raise(Fluent::ConfigError) do
        create_driver('')
      end
    end

    test "simple" do
      d = create_driver %[
        host            localhost
        port            3306
        interval        30
        tag             input.mysql
        query           SHOW VARIABLES LIKE 'Thread_%'
        record_hostname yes
      ]
      assert_equal 'localhost', d.instance.host
      assert_equal 3306, d.instance.port
      assert_equal 30, d.instance.interval
      assert_equal 'input.mysql', d.instance.tag
      assert_equal true, d.instance.record_hostname
      assert_equal false, d.instance.nest_result
    end
  end
end
