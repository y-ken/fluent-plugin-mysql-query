require 'fluent/plugin/input'
require 'mysql2'

module Fluent::Plugin
  class MysqlQueryInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('mysql_query', self)

    helpers :timer

    config_param :host, :string, default: 'localhost'
    config_param :port, :integer, default: 3306
    config_param :username, :string, default: 'root'
    config_param :password, :string, default: nil, secret: true
    config_param :database, :string, default: nil
    config_param :encoding, :string, default: 'utf8'
    config_param :interval, :time, default: '1m'
    config_param :tag, :string
    config_param :query, :string
    config_param :nest_result, :bool, default: false
    config_param :nest_key, :string, default: 'result'
    config_param :row_count, :bool, default: false
    config_param :row_count_key, :string, default: 'row_count'
    config_param :record_hostname, :bool, default: false

    def configure(conf)
      super
      @hostname = nil
      $log.info "adding mysql_query job: [#{@query}] interval: #{@interval}sec"
    end

    def start
      super
      timer_execute(:in_mysql_query, @interval, &method(:on_timer))
    end

    def on_timer
      @hostname = get_mysql_hostname if @hostname.nil?
      tag = "#{@tag}".gsub('__HOSTNAME__', @hostname).gsub('${hostname}', @hostname)
      record = Hash.new
      record.store('hostname', @hostname) if @record_hostname
      result = get_exec_result
      record.store(@row_count_key, result.size) if @row_count
      if (@nest_result)
        record.store(@nest_key, result)
        router.emit(tag, Engine.now, record)
      else
        result.each do |data|
          router.emit(tag, Engine.now, record.merge(data))
        end
      end
    end

    def get_connection
      begin
        return Mysql2::Client.new({
          host: @host,
          port: @port,
          username: @username,
          password: @password,
          database: @database,
          encoding: @encoding,
          reconnect: true
        })
      rescue Exception => e
        log.warn "mysql_query: #{e}"
        sleep @interval
        retry
      end
    end

    def query(query)
      @mysql ||= get_connection
      begin
        return @mysql.query(query, cast: false, cache_rows: false)
      rescue Exception => e
        log.warn "mysql_query: #{e}"
        sleep @interval
        retry
      end
    end

    def get_mysql_hostname
      query("SHOW VARIABLES LIKE 'hostname'").each do |row|
        return row.fetch('Value')
      end
      # hostname variable is not present
      return ''
    end

    def get_exec_result
      result = Array.new
      stmt = query(@query)
      stmt.each do |row|
        result.push(row)
      end
      return result
    end
  end
end
