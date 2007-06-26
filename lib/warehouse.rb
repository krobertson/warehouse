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

  class << self
    attr_accessor :domain, :forum_url, :permission_command, :password_command, :mail_from, :version
  end
  self.domain    = ''
  self.forum_url = "http://forum.activereload.net/licenses/%s/installs"
  self.version   = Version.new(0, 9, 0)
end