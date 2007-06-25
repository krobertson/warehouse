module Importer
  class User < Base
    table 'users'
    
    def self.find_all_by_logins(logins)
      find_all("`login` IN (#{logins.collect { |l| quote_string(l) } * ', '})")
    end
  end
end