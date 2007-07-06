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
    attr_accessor :domain, :forum_url, :permission_command, :password_command, :mail_from, :version, :default_session_options
  end
  self.default_session_options = {:session_key => '_warehouse_session_id', :secret => 'asMb0bEBw6TXU'}
  self.domain    = ''
  self.forum_url = "http://forum.activereload.net/licenses/%s/installs"
  self.version   = Version.new(1, 0, 1)
end