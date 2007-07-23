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
    require 'lib/cache_key'
    $LOAD_PATH << 'vendor/ruby-sequel/lib'
    require 'lib/warehouse/command'
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
    @command = Warehouse::Command.new(config)
  end

  task :post_commit do
    ENV['REPO'] ||= ENV['REPO_PATH'].split('/').last if ENV['REPO_PATH']
    Rake::Task['warehouse:sync'].invoke
    # eventually add other stuff here, like email
  end
  
  task :build_htpasswd => :init do
    @command.write_users_to_htpasswd(ENV['CONFIG'] || 'config/htpasswd.conf')
  end
  
  task :build_repo_htpasswd => :find_repo do
    @command.write_repo_users_to_htpasswd(@repo, ENV['CONFIG'] || 'config/htpasswd.conf')
  end
  
  task :build_user_htpasswd => :init do
    raise "Need htpasswd config path with :repo variable.  CONFIG=/svn/:repo/.htaccess" unless ENV['CONFIG'].to_s[/:repo/]
    raise "Need single user id. USER=234" unless ENV['USER']
    @command.write_repo_users_to_htpasswd @command.repos_from_user(:id => user), ENV['CONFIG']
  end
  
  # CONFIG
  # EMAIL
  # REPO
  # REPO_PATH
  # REPO_ACCESS r/rw
  task :import_users => :environment do
    raise "Need an htpasswd file to import.  CONFIG=/path/to/htpasswd" unless ENV['CONFIG']
    @command.import_users_from_htpasswd ENV['CONFIG'], ENV['EMAIL'], ENV['REPO'], ENV['REPO_PATH'], ENV['REPO_ACCESS']
  end
  
  task :build_config => :init do
    require 'lib/warehouse'
    require 'config/initializers/warehouse'
    config_path = ENV['CONFIG'] || 'config/access.conf'
    
    if ENV['REPO']
      @command.build_config config_path
    else
      @command.build_config_for ENV['REPO'], config_path
    end
  end

  task :sync => :init do
    require 'active_support'
    # time to beat: 153
    now = Time.now.to_i
    if ENV['REPO']
      if repo = find_first_repo(ENV['REPO'])
        puts "Syncing revisions for #{repo[:name].inspect}"
        @command.sync_revisions_for(repo, @num)
      else
        puts "No repo(s) found, REPO=#{ENV['REPO'].inspect} given."
      end
    else
      @command.sync_revisions @num
    end
    puts Time.now.to_i - now
  end

  task :clear => :init do
    if ENV['REPO']
      repo = find_first_repo(ENV['REPO'])
      if repo
        @command.clear_changesets_for repo
        puts "All revisions for #{repo[:name].inspect} were cleared."
      else
        puts "No repo(s) found, REPO=#{ENV['REPO'].inspect} given."
      end
    else
      @command.clear_changesets
      puts "All revisions for all repositories were cleared"
    end
  end

  task :find_repo => :init do
    @repo = find_first_repo(ENV['REPO'])
    raise "Please select a repo with REPO=id or REPO=repoository_subdomain" if @repo.nil?
  end
  
  def find_first_repo(value)
    @command.send(:find_repo, ENV['REPO'])
  end
end