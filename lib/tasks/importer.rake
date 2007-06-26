module Kernel
  # Require a library with fallback to RubyGems.  Warnings during library
  # loading are silenced to increase signal/noise for application warnings.
  def require_library_or_gem(library_name)
    begin
      require library_name
    rescue LoadError => cannot_require
      # 1. Requiring the module is unsuccessful, maybe it's a gem and nobody required rubygems yet. Try.
      begin
        require 'rubygems'
      rescue LoadError => rubygems_not_installed
        raise cannot_require
      end
      # 2. Rubygems is installed and loaded. Try to load the library again
      begin
        require library_name
      rescue LoadError => gem_not_installed
        raise cannot_require
      end
    end
  end
end

namespace :warehouse do
  task :init do
    require 'config/initializers/svn'
    require 'importer/base'
    config = {}
    YAML.load_file("config/database.yml")[RAILS_ENV].each do |k, v|
      config[k.to_sym] = v
    end
    Importer::MysqlAdapter.create config
  end

  task :post_commit => :sync do
    # eventually add other stuff here, like email
  end
  
  task :build_htpasswd => :init do
    require 'webrick'
    write_users_to_htpasswd(Importer::User.find_all, ENV['CONFIG'] || 'config/svn.htpasswd')
  end
  
  task :build_repo_htpasswd => :find_repo do
    require 'webrick'
    write_repo_users_to_htpasswd(@repo, ENV['CONFIG'] || 'config/svn.htpasswd')
  end
  
  task :build_user_htpasswd => :init do
    require 'webrick'
    raise "Need htpasswd config path with :repo variable.  CONFIG=/svn/:repo/.htaccess" unless ENV['CONFIG'].to_s[/:repo/]
    raise "Need single user id. USER=234" unless ENV['USER']
    user         = Importer::User.find_by_id(ENV['USER'])
    write_repo_users_to_htpasswd user.repositories, ENV['CONFIG']
  end
  
  def write_repo_users_to_htpasswd(repos, htpasswd_path)
    [repos].flatten.each do |repo|
      write_users_to_htpasswd(repo.users, htpasswd_path.gsub(/:repo/, repo.attributes['subdomain']))
    end
  end
  
  def write_users_to_htpasswd(users, htpasswd_path)
    htpasswd = WEBrick::HTTPAuth::Htpasswd.new(htpasswd_path)
    htpasswd.each do |(user, passwd)|
      htpasswd.delete_passwd(nil, user)
    end
    users.each do |user|
      next if user.attributes['login'].to_s == '' || user.attributes['crypted_password'].to_s == ''
      htpasswd.instance_variable_get("@passwd")[user.attributes['login']] = user.attributes['crypted_password']
    end
    htpasswd.flush
  end
  
  task :build_config => :init do
    require 'lib/warehouse'
    require 'config/initializers/warehouse'
    config_path = ENV['CONFIG'] || 'config/svn.conf'
    
    repo_id = ENV['REPO'].to_i
    repositories = 
      if ENV['REPO'].nil?
        Importer::Repository.find_all
      else
        [repo_id > 0 ?  Importer::Repository.find_by_id(repo_id) : Importer::Repository.find_first("name = '#{ENV['REPO']}'")]
      end
    permissions = Importer::Permission.find_all_by_repositories(repositories).inject({}) do |memo, perm| 
      (memo[perm.attributes['repository_id'].to_s] ||= []) << perm; memo
    end
    users = Importer::User.find_all_by_permissions(permissions.values.flatten).inject({}) { |memo, user| memo.update(user.attributes['id'].to_s => user) }
    permissions.each do |repo_id, perms|
      permissions[repo_id] = perms.inject({}) do |memo, p|
        (memo[p.attributes['path']] ||= []) << p; memo
      end
    end

    open(config_path, 'w') do |file|
      repositories.each do |repo|
        perms_hash = permissions[repo.attributes['id'].to_s]
        next if perms_hash.nil?
        perms_hash.each do |path, perms|
          file.write("[%s]:/%s\n" % [repo.attributes['subdomain'], path])
          perms.each do |p|
            if p.attributes['user_id'].nil?
              file.write('*')
            else
              file.write(users[p.attributes['user_id'].to_s].attributes['login'])
            end
            file.write(' = r')
            file.write('w') if p.attributes['full_access'] == '1'
            file.write("\n")
          end
          file.write("\n")
        end
      end
    end
  end

  task :sync => :find_repo do
    @repo.sync_revisions(@num)
  end

  task :clear => :find_repo do
    @repo.clear_revisions!
    puts "All repositories for #{@repo.attributes['name'].inspect} were cleared."
  end

  task :find_repo => :init do
    @num  = (ENV['NUM'] || ENV['N']).to_i
    @repo = find_first_repo(ENV['REPO'])
    raise "Please select a repo with REPO=id or REPO=repository_name" if @repo.nil?
  end
  
  def find_first_repo(value)
    repo_id = value.to_i
    repo_id > 0 ?  Importer::Repository.find_by_id(repo_id) : Importer::Repository.find_first("name = '#{value}'")
  end
end