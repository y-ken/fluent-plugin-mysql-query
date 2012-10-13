module Fluent
  class MysqlQueryInput < Fluent::Input
    Plugin.register_input('mysql_query', self)

    def initialize
      require 'mysql2'
      super
    end

    config_param :host, :string, :default => 'localhost'
    config_param :port, :integer, :default => 3306
    config_param :username, :string, :default => 'root'
    config_param :password, :string, :default => nil
    config_param :database, :string, :default => nil
    config_param :encoding, :string, :default => 'utf8'
    config_param :interval, :string, :default => '1m'
    config_param :record_hostname, :string, :default => nil
    config_param :tag, :string
    config_param :query, :string

    def configure(conf)
      super
      @interval = Config.time_value(@interval)
      @record_hostname = @record_hostname || false
      @hostname = get_mysql_hostname
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
        con = query(@query)
        con.each do |row|
          tag = "#{@tag}".gsub('__HOSTNAME__', @hostname).gsub('${hostname}', @hostname)
          record = Hash.new
          record.store('hostname', @hostname) if @record_hostname
          record.merge!(row)
          Engine.emit(tag, Engine.now, record)
        end
        sleep @interval
      end
    end

    def get_connection
      return Mysql2::Client.new({
        :host => @host, 
        :port => @port,
        :username => @username,
        :password => @password,
        :database => @database,
        :encoding => @encoding,
        :reconnect => true
      })
    end

    def query(query)
      @mysql ||= get_connection
      begin
        return @mysql.query(query)
      rescue Exception => e
        $log.info "#{e.inspect}"
      end
    end

    def get_mysql_hostname
      query("SHOW VARIABLES LIKE 'hostname'").each do |row|
        return row.fetch('Value')
      end
    end
  end
end
