module Silo
  class Repository
    attr_reader :options
    
    def initialize(adapter_type = :mock, options = {})
      set_adapter(adapter_type, options)
    end
    
    def node_at(path, revision = nil)
      Node.new(self, path, revision)
    end

    def set_adapter(adapter_type = :mock, options = {})
      @options = options
      require "silo/adapters/#{adapter_type}"
      extend Silo::Adapters.const_get(adapter_type.to_s.capitalize)
    end

  protected
    def convert_to_utf8(content, mime_type, content_charset = 'utf-8')
      unless mime_type.nil? || mime_type.size.zero?
        content_charset = mime_type.slice(%r{charset=([A-Za-z0-9\-_]+)}, 1) || content_charset
      end
      return content if content_charset == 'utf-8'
      Iconv.conv('utf-8', content_charset, content) rescue content
    end
  end
end