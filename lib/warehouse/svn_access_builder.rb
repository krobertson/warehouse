require 'erubis'
module Warehouse
  class SvnAccessBuilder
    def initialize(repositories, permissions, users, config = 'config/svn_access.erb')
      repositories.each do |repo|
        repo[:base_path]   = repo[:path].to_s.split("/").last.to_s
        repo[:permissions] = permissions[repo[:id].to_s]
        repo[:permissions].each do |path, perms|
          perms.each do |p|
            p[:user_login] = p[:user_id] ? (users[p[:user_id].to_s][:login] rescue '') : '*'
          end
        end
      end
      @repositories = repositories
      @config       = config
    end
    
    def true?(value)
      value.to_s == /^t/ || value.to_i == 1
    end
    
    def render
      eval Erubis::Eruby.new.convert(IO.read(File.join(RAILS_ROOT, @config)))
    end
  end
end