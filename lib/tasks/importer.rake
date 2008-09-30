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
    require 'set'
    require 'logger'
    require 'yaml'
    require 'config/initializers/svn'
    require 'lib/cache_key'
    $LOAD_PATH << 'vendor/ruby-sequel/lib' << 'vendor/metaid-1.0' << 'vendor/mailfactory-1.2.3/lib'
    require 'lib/warehouse'
    require 'config/initializers/warehouse'
    require 'lib/warehouse/mailer'
    require 'lib/warehouse/command'
    require 'lib/warehouse/extension'
    require 'lib/warehouse/hooks'
    require 'lib/warehouse/hooks/base'
    require 'lib/warehouse/hooks/commit'
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
    Warehouse::Command.logger ||= Logger.new(ENV['LOGGER'] || STDOUT) unless ENV['LOGGER'] == 'none'
    Warehouse::Command.logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'INFO').upcase) if Warehouse::Command.logger
    @command = Warehouse::Command.new(config)
  end

  task :post_commit => :init do
    ENV['REPO'] ||= ENV['REPO_PATH'].split('/').last if ENV['REPO_PATH']
    Rake::Task['warehouse:sync'].invoke
    Warehouse::Hooks.discover
    @command.process_hooks_for(ENV['REPO'], ENV['REPO_PATH'], ENV['REVISION'] || ENV['CHANGESET'])
  end
  
  task :build_htpasswd => :init do
    @command.write_users_to_htpasswd(ENV['CONFIG'] || 'config/htpasswd.conf')
  end
  
  task :build_repo_htpasswd => :init do
    @command.write_repo_users_to_htpasswd(ENV['REPO'], ENV['CONFIG'] || 'config/htpasswd.conf')
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
  task :import_users => :init do
    raise "Need an htpasswd file to import.  CONFIG=/path/to/htpasswd" unless ENV['CONFIG']
    @command.import_users_from_htpasswd ENV['CONFIG'], ENV['EMAIL'], ENV['REPO'], ENV['REPO_PATH'], ENV['REPO_ACCESS']
  end
  
  task :build_config => :init do
    require 'lib/warehouse'
    require 'config/initializers/warehouse'
    config_path = ENV['CONFIG'] || 'config/access.conf'
    
    @command.build_config_for ENV['REPO'], config_path
  end

  task :sync => :init do
    @command.sync_revisions_for(ENV['REPO'], @num)
  end

  task :clear => :init do
    @command.clear_changesets_for ENV['REPO']
  end
end