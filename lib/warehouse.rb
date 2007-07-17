module Warehouse
  class Version
    attr_reader :major, :minor, :tiny
    
    def initialize(major, minor, tiny)
      @major = major
      @minor = minor
      @tiny  = tiny
    end
    
    def ==(version)
      if version.is_a? Version
        version.major == major && version.minor == minor && version.tiny == tiny
      else
        version.to_s == to_s
      end
    end
    
    def to_s
      @string ||= [@major, @minor, @tiny] * '.'
    end
    
    alias_method :inspect, :to_s
  end

  def self.session_options
    default_session_options.merge :session_domain => Warehouse.domain, :session_path => '/'
  end

  class << self
    attr_accessor :domain, :forum_url, :permission_command, :password_command, :mail_from, :version, :default_session_options, :smtp_settings, :sendmail_settings, :mail_type, :caching, :config_path, :syncing
    
    def sync?
      syncing.nil? || syncing == '1'
    end
    
    def setup!(&block)
      class_eval(&block) if block
      setup_mail!
      setup_caching!
    end
    
    def setup_mail!
      ActionMailer::Base.delivery_method = :test
      return if RAILS_ENV == 'test' || mail_type.nil? || send("#{mail_type}_settings").nil? || send("#{mail_type}_settings").empty?
      ActionMailer::Base.delivery_method = mail_type.to_sym
      ActionMailer::Base.send("#{mail_type}_settings=", send("#{mail_type}_settings"))
    end
    
    def setup_caching!
      ActionController::Base.perform_caching = false
      return if caching.nil? || caching.empty?
      ActionController::Base.perform_caching = true
      ActionController::Base.fragment_cache_store = :file_store, File.join(RAILS_ROOT, 'tmp', 'cache')
    end

    def write_config_file(attributes = {})
      domain_is_blank = domain.nil? || domain.empty?
      tmpl = ['# This file is auto generated.  Visit /admin/settings to change it.', '#', "require 'warehouse' unless Object.const_defined?(:Warehouse)", '', 'Warehouse.setup! do']
      attributes.each do |key, value|
        case value
          when Hash
            send "#{key}=", Hash.new
            value.each do |option, option_value|
              send(key)[option.to_sym] = option_value
              tmpl << "  @#{key}[:#{option}] = #{option_value.inspect}"
            end
          else
            send "#{key}=", (value.blank? ? nil : value)
            tmpl << "  @#{key} = #{value.inspect}" unless value.blank?
        end
      end
      tmpl << 'end' << ''
      setup!

      File.open(File.symlink?(config_path) ? File.readlink(config_path) : config_path, 'w') do |f|
        f.write tmpl.join("\n")
      end
      
      self.class.session(Warehouse.session_options) if domain_is_blank && !attributes[:domain].blank?
    end
  end

  self.config_path = File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')
  self.default_session_options = {:session_key => '_warehouse_session_id', :secret => 'asMb0bEBw6TXU'}
  self.domain    = ''
  self.forum_url = "http://forum.activereload.net/licenses/%s/installs"
  self.version   = Version.new(1, 0, 3)
  self.smtp_settings = self.sendmail_settings = {}
end