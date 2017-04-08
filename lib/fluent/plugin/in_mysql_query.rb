require 'fluent/input'

module Fluent
  class MysqlQueryInput < Fluent::Input
    Plugin.register_input('mysql_query', self)

    # Define `router` method to support v0.10.57 or earlier
    unless method_defined?(:router)
      define_method("router") { Fluent::Engine }
    end

    def initialize
      require 'mysql2'
      super
    end

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 3306
    config_param :username, :string, :default => 'root'
    config_param :password, :string, :default => nil, :secret => true
    config_param :database, :string, :default => nil
    config_param :encoding, :string, :default => 'utf8'
    config_param :interval, :time, :default => '1m'
    config_param :tag, :string
    config_param :query, :string
    config_param :nest_result, :bool, :default => false
    config_param :nest_key, :string, :default => 'result'
    config_param :row_count, :bool, :default => false
    config_param :row_count_key, :string, :default => 'row_count'
    config_param :record_hostname, :bool, :default => false

    def configure(conf)
      super
      @hostname = nil
      $log.info "adding mysql_query job: [#{@query}] interval: #{@interval}sec"
    end

    def start
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      Thread.kill(@thread)
    end

    def run
      loop do
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
        sleep @interval
      end
    end

    def get_connection
      begin
        return Mysql2::Client.new({
          :host => @host,
          :port => @port,
          :username => @username,
          :password => @password,
          :database => @database,
          :encoding => @encoding,
          :reconnect => true
        })
      rescue Exception => e
        $log.warn "mysql_query: #{e}"
        sleep @interval
        retry
      end
    end

    def query(query)
      @mysql ||= get_connection
      begin
        return @mysql.query(query, :cast => false, :cache_rows => false)
      rescue Exception => e
        $log.warn "mysql_query: #{e}"
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
