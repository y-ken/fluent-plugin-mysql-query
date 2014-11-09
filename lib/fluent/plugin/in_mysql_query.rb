module Fluent
  class MysqlQueryInput < Fluent::Input
    Plugin.register_input('mysql_query', self)

    def initialize
      require 'mysql2'
      require 'rufus-scheduler'
      @scheduler = Rufus::Scheduler.new
      super
    end

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 3306
    config_param :username, :string, :default => 'root'
    config_param :password, :string, :default => nil
    config_param :database, :string, :default => nil
    config_param :encoding, :string, :default => 'utf8'
    config_param :interval, :string, :default => nil
    config_param :cron, :string, :default => nil
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
      #$log.info "adding mysql_query job: [#{@query}] interval: #{@interval}sec"
    end

    def start

      unless @cron and @interval
        @thread = Thread.new(&method(:run))
      end

      if @cron
        @thread = Thread.new(&method(:run_cron))
      end

      if @interval
        @thread = Thread.new(&method(:run_interval))
      end
      
    end

    def shutdown
      Thread.kill(@thread)
    end

    def run
      @hostname = get_mysql_hostname if @hostname.nil?
      tag = "#{@tag}".gsub('__HOSTNAME__', @hostname).gsub('${hostname}', @hostname)
      record = Hash.new
      record.store('hostname', @hostname) if @record_hostname
      result = get_exec_result
      record.store(@row_count_key, result.size) if @row_count
      if (@nest_result)
        record.store(@nest_key, result)
        Engine.emit(tag, Engine.now, record)
      else
        result.each do |data|
          Engine.emit(tag, Engine.now, record.merge(data))
        end
      end
    end

    def run_cron
      @scheduler.cron @cron do
        run()
      end
      @scheduler.join
    end

    def run_interval
      @scheduler.interval @interval do
        run()
      end
      @scheduler.join
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
