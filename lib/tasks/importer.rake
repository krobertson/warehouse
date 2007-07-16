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
    require 'yaml'
    require 'config/initializers/svn'
    require 'importer/base'
    ENV['DB_CONFIG'] ||= "config/database.yml"
    raise "No database config at #{ENV['DB_CONFIG'].inspect}" unless File.exist?(ENV['DB_CONFIG'])
    config = {}
    yaml_config = YAML.load_file(ENV['DB_CONFIG'])
    raise "Empty database config at #{ENV['DB_CONFIG'].inspect}" if yaml_config.nil? || yaml_config.empty?
    raise "No database config for #{RAILS_ENV} environment at #{ENV['DB_CONFIG'].inspect}" if yaml_config[RAILS_ENV].nil? || yaml_config[RAILS_ENV].empty?
    yaml_config[RAILS_ENV].each do |k, v|
      config[k.to_sym] = v
    end
    @num  = (ENV['NUM'] || ENV['N']).to_i
    Importer::MysqlAdapter.create config
  end

  task :post_commit do
    ENV['REPO'] ||= ENV['REPO_PATH'].split('/').last if ENV['REPO_PATH']
    Rake::Task['warehouse:sync'].invoke
    # eventually add other stuff here, like email
  end
  
  task :build_htpasswd => :init do
    require 'webrick'
    write_users_to_htpasswd(Importer::User.find_all, ENV['CONFIG'] || 'config/htpasswd.conf')
  end
  
  task :build_repo_htpasswd => :find_repo do
    require 'webrick'
    write_repo_users_to_htpasswd(@repo, ENV['CONFIG'] || 'config/htpasswd.conf')
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
  
  # CONFIG
  # EMAIL
  # REPO
  # REPO_PATH
  # REPO_ACCESS r/rw
  task :import_users => :environment do
    require 'webrick'
    raise "Need an htpasswd file to import.  CONFIG=/path/to/htpasswd" unless ENV['CONFIG']
    repo = ENV['REPO'].blank? ? nil : Repository.find_by_subdomain(ENV['REPO'])
    User.transaction do
      WEBrick::HTTPAuth::Htpasswd.new(ENV['CONFIG']).each do |(login, passwd)|
        user = User.new(:login => login)
        user.crypted_password = passwd
        user.email = "#{login}@#{ENV['EMAIL'] || 'unknown.net'}"
        i = 1
        user.login = "#{login}_#{i+=1}" until user.valid?
        user.save!
        
        next if repo.nil?
        repo.grant(:path => ENV['REPO_PATH'].to_s, :user => user, :full_access => ENV['REPO_ACCESS'] == 'rw')
      end
    end
  end
  
  task :build_config => :init do
    require 'lib/warehouse'
    require 'lib/cache_key'
    require 'config/initializers/warehouse'
    config_path = ENV['CONFIG'] || 'config/access.conf'
    
    repo_id = ENV['REPO'].to_i
    repositories = 
      if ENV['REPO'].nil?
        Importer::Repository.find_all
      else
        [repo_id > 0 ?  Importer::Repository.find_by_id(repo_id) : Importer::Repository.find_first("subdomain = '#{ENV['REPO']}'")]
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
          file.write("[%s:/%s]\n" % [repo.attributes['subdomain'], path])
          perms.each do |p|
            login = users[p.attributes['user_id'].to_s].attributes['login']
            next if login.nil? || login.size == 0
            if p.attributes['user_id'].nil?
              file.write('*')
            else
              file.write(login)
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

  task :sync => :init do
    (ENV['REPO'] ? [find_first_repo(ENV['REPO'])] : Importer::Repository.find_all).each do |repo|
      if repo
        puts "Syncing revisions for #{repo.attributes['name'].inspect}"
        repo.sync_revisions(@num)
      else
        puts "No repo(s) found, REPO=#{ENV['REPO'].inspect} given."
      end
    end
    CacheKey.sweep_cache
  end

  task :clear => :init do
    (ENV['REPO'] ? [find_first_repo(ENV['REPO'])] : Importer::Repository.find_all).each do |repo|
      if repo
        repo.clear_revisions!
        puts "All repositories for #{repo.attributes['name'].inspect} were cleared."
      else
        puts "No repo(s) found, REPO=#{ENV['REPO'].inspect} given."
      end
    end
  end

  task :find_repo => :init do
    @repo = find_first_repo(ENV['REPO'])
    raise "Please select a repo with REPO=id or REPO=repository_subdomain" if @repo.nil?
  end
  
  def find_first_repo(value)
    repo_id = value.to_i
    repo_id > 0 ?  Importer::Repository.find_by_id(repo_id) : Importer::Repository.find_first("subdomain = '#{value}'")
  end
end