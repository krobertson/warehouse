module Importer
  class User < Base
    table 'users'
    
    def self.find_all_by_logins(logins)
      find_all("`login` IN (#{logins.collect { |l| quote_string(l) } * ', '})")
    end
    
    def self.find_all_by_permissions(permissions)
      find_all("`id` IN (#{permissions.collect { |p| quote_string(p.attributes['user_id']) }.uniq * ', '})")
    end
  end
end