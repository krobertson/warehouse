module Importer
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
    
    def self.find_all(conditions)
      adapter.select("SELECT * FROM `#{table}` WHERE #{conditions}")
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
    
    def quote_string(string)
      self.class.adapter.quote_string string
    end
    
    def self.adapter
      Importer::MysqlAdapter.instance
    end
  end
end

require 'importer/mysql_adapter'
require 'importer/repository'
require 'importer/changeset'
require 'importer/change'