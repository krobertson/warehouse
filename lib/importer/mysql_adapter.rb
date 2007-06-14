module Importer
  module MysqlAdapter
    class Base
      attr_reader :attributes

      def self.table(value = nil)
        @table = value unless value.nil?
        @table
      end
      
      def initialize(attributes)
        @attributes = attributes
      end
      
      def self.find_by_id(id)
        row = adapter.select("SELECT * FROM `#{table}` WHERE id = #{quote_string id}").first
        row ? new(row) : nil
      end
      
      def self.find_first(conditions)
        row = adapter.select("SELECT * FROM `#{table}` WHERE #{conditions} LIMIT 1").first
        row ? new(row) : nil
      end
      
      def self.delete(id)
        delete_all "id = #{quote_string id}"
      end
      
      def self.delete_all(conditions = nil)
        adapter.execute("DELETE FROM `#{table}` #{conditions}")
      end
      
      def self.quote_string(string)
        adapter.quote_string string
      end
      
      def self.insert(columns, values)
        find_by_id adapter.insert(table, columns, values)
      end
      
      def self.transaction
        adapter.execute "BEGIN"
        yield
        adapter.execute "COMMIT"
      rescue
        adapter.execute "ROLLBACK"
        raise
      end
      
      def transaction(&block)
        self.class.transaction(&block)
      end
      
      def quote_string(string)
        self.class.adapter.quote_string string
      end
      
      protected
        def self.adapter
          Importer::MysqlAdapter.instance
        end
    end
    
    class Adapter
      def initialize(options)
        options[:username] = options[:username] ? options[:username].to_s : 'root'
        options[:password] = options[:password].to_s
        unless options.has_key?(:database)
          raise ArgumentError, "No database specified. Missing argument: database."
        end
        
        Importer::MysqlAdapter.require_mysql
        
        @options = options
        @connection = Mysql.init
        @connection.ssl_set(options[:sslkey], options[:sslcert], options[:sslca], options[:sslcapath], options[:sslcipher]) if options[:sslkey]
        encoding = options[:encoding]
        if encoding
          @connection.options(Mysql::SET_CHARSET_NAME, encoding) rescue nil
        end
    
        @connection.real_connect(options[:host], options[:username], options[:password], options[:database], options[:port], options[:socket])
        execute("SET NAMES '#{encoding}'") if encoding
    
        # By default, MySQL 'where id is null' selects the last inserted id.
        # Turn this off. http://dev.rubyonrails.org/ticket/6778
        execute("SET SQL_AUTO_IS_NULL=0")
      end
    
      def quote_string(string) #:nodoc:
        "'#{@connection.quote(string.to_s)}'"
      end
    
      def execute(sql)
        @connection.query(sql)
      end
    
      def select(sql)
        @connection.query_with_result = true
        result = execute(sql)
        rows = result.all_hashes
        result.free
        rows
      end
      
      def insert(table, columns, values)
        execute("INSERT INTO `#{table}` (#{columns.collect { |c| "`#{c}`" } * ', '}) VALUES (#{values.collect { |v| quote_string v } * ', '});")
        @connection.insert_id
      end
    end

    class << self
      attr_reader :instance
      def create(options)
        @instance = Adapter.new(options)
      end
    end

    def self.require_mysql
      # Include the MySQL driver if one hasn't already been loaded
      unless defined? Mysql
        begin
          require_library_or_gem 'mysql'
        rescue LoadError => cannot_require_mysql
          # Use the bundled Ruby/MySQL driver if no driver is already in place
          begin
            require 'active_record/vendor/mysql'
          rescue LoadError
            raise cannot_require_mysql
          end
        end
      end
    
      # Define Mysql::Result.all_hashes
      define_all_hashes_method!
    end
    
    # add all_hashes method to standard mysql-c bindings or pure ruby version
    def self.define_all_hashes_method!
      raise 'Mysql not loaded' unless defined?(::Mysql)
    
      target = defined?(Mysql::Result) ? Mysql::Result : MysqlRes
      return if target.instance_methods.include?('all_hashes')
    
      # Ruby driver has a version string and returns null values in each_hash
      # C driver >= 2.7 returns null values in each_hash
      if Mysql.const_defined?(:VERSION) && (Mysql::VERSION.is_a?(String) || Mysql::VERSION >= 20700)
        target.class_eval <<-'end_eval'
        def all_hashes
          rows = []
          each_hash { |row| rows << row }
          rows
        end
        end_eval
    
      # adapters before 2.7 don't have a version constant
      # and don't return null values in each_hash
      else
        target.class_eval <<-'end_eval'
        def all_hashes
          rows = []
          all_fields = fetch_fields.inject({}) { |fields, f| fields[f.name] = nil; fields }
          each_hash { |row| rows << all_fields.dup.update(row) }
          rows
        end
        end_eval
      end
    
      unless target.instance_methods.include?('all_hashes')
        raise "Failed to defined #{target.name}#all_hashes method. Mysql::VERSION = #{Mysql::VERSION.inspect}"
      end
    end
  end
end