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
    default_session_options.merge :session_domain => ".#{Warehouse.domain}", :session_path => '/'
  end

  def self.source_highlight_themes
    Dir.chdir File.join(RAILS_ROOT, 'public', 'stylesheets', 'uv') do
      Dir["*.css"].collect! { |theme| theme.sub!(/\.css$/, ''); [theme.titleize, theme] }
    end
  end

  class << self
    attr_accessor :domain, :forum_url, :permission_command, :password_command, :mail_from, :version, 
      :default_session_options, :smtp_settings, :sendmail_settings, :mail_type, :caching, :config_path, 
      :syncing, :authentication_scheme, :authentication_realm, :setup, :svnlook_path, :source_highlight_theme
    
    def setup?
      @setup == true
    end
    
    def sync?
      syncing.nil? || syncing == '1'
    end
    
    def setup!(&block)
      return if setup?
      self.setup = true
      class_eval(&block) if block
      setup_mail!
      setup_caching!
      if Object.const_defined?(:USE_REPO_PATHS) && USE_REPO_PATHS
        puts "** Using paths for repositories, instead of subdomains.  http://#{Warehouse.domain || 'my-domain.com'}/my-repo/browser, etc."
      end
    end
    
    def setup_mail!
      if Object.const_defined?(:ActionMailer)
        ActionMailer::Base.delivery_method = :test
        return if RAILS_ENV == 'test' || mail_type.nil? || send("#{mail_type}_settings").nil? || send("#{mail_type}_settings").empty?
        ActionMailer::Base.delivery_method = mail_type.to_sym
        ActionMailer::Base.send("#{mail_type}_settings=", send("#{mail_type}_settings"))
      elsif Warehouse.const_defined?(:Mailer)
        Warehouse::Mailer.delivery_method = :test_send
        return if RAILS_ENV == 'test' || mail_type.nil? || send("#{mail_type}_settings").nil? || send("#{mail_type}_settings").empty?
        options   = send("#{mail_type}_settings")
        Warehouse::Mailer.delivery_method = mail_type == 'smtp' ? :net_smtp : :sendmail
        Warehouse::Mailer.config = {}
        return if Warehouse::Mailer.delivery_method == :sendmail
        Warehouse::Mailer.config[:domain] = options[:domain]         if options[:domain] && options[:domain].size > 0
        Warehouse::Mailer.config[:host]   = options[:address]        if options[:address] && options[:address].size > 0
        Warehouse::Mailer.config[:port]   = options[:port]           if options[:port]
        Warehouse::Mailer.config[:user]   = options[:user_name]      if options[:user_name] && options[:user_name].size > 0
        Warehouse::Mailer.config[:pass]   = options[:password]       if options[:password] && options[:password].size > 0
        Warehouse::Mailer.config[:auth]   = options[:authentication] if options[:authentication] && options[:authentication].size > 0
      end
    end
    
    def setup_caching!
      return unless Object.const_defined?(:ActionController)
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
      
      ApplicationController.session(Warehouse.session_options) if domain_is_blank && !attributes[:domain].blank?
    end
  end

  self.config_path             ||= File.join(RAILS_ROOT, 'config', 'initializers', 'warehouse.rb')
  self.default_session_options ||= {:session_key => '_warehouse_session_id', :secret => '4b3eaf64bfa62da140e0f45c9030f272'}
  self.domain                  ||= ''
  self.forum_url               ||= "http://forum.activereload.net/licenses/%s/installs"
  self.version                 ||= Version.new(1, 1, 6)
  self.smtp_settings           ||= self.sendmail_settings ||= {}
  self.authentication_scheme   ||= 'basic' # plain / md5
  self.authentication_realm    ||= ''
  self.svnlook_path            ||= '/usr/bin/svnlook'
  self.source_highlight_theme  ||= :twilight
end

unless !File.exist?(File.join(RAILS_ROOT, 'config/initializers/warehouse'))
  require 'config/initializers/warehouse'
end

if Object.const_defined?(:Dependencies)
  Dependencies.autoloaded_constants.delete 'Warehouse'
end