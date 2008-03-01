require 'metaid'
module Warehouse
  class Command
    class << self
      attr_accessor :logger, :connection
    
      def configure(config)
        @connection = Sequel(yaml_to_connection_string(config))
      end

      def yaml_to_connection_string(config)
        case config[:adapter]
          when 'sqlite' then raise "Sequel does not support sqlite, use sqlite3"
          when 'sqlite3'
            require "sequel/sqlite"
            "sqlite://%s" % config[:database]
          else
            config[:host]  ||= 'localhost'
            config[:adapter] = 'postgres' if config[:adapter].to_s =~ /^postgre/ # supports postgres, postgresql, etc
            require "sequel/#{config[:adapter]}"
            Sequel::Database.single_threaded = true
            "%s://%s:%s@%s/%s" % %w(adapter username password host database).collect! { |key| config[key.to_sym] }
        end
      end
    end
    
    # Sequel object
    attr_reader :connection

    def initialize(config = nil)
      configure(config) if config
      @connection ||= self.class.connection
    end
    
    def configure(config)
      @connection = Sequel(self.class.yaml_to_connection_string(config))
    end

    def sync_revisions_for(repo_subdomain, num = 0)
      if repo_subdomain.nil?
        connection[:repositories].all.each do |repo|
          sync_revisions_for repo, num
        end
        return
      end
      repo = find_repo(repo_subdomain)
      unless repo
        puts "no repository found for the '#{repo_subdomain}' subdomain", :warn
        return
      end
      unless silo_for(repo)
        puts "No SVN repository found for '#{repo[:subdomain]}' in '#{repo[:path]}'", :warn
        return
      end

      Warehouse::Syncer.const_get(repo[:scm_type].capitalize + "Syncer").process(connection, repo, silo_for(repo), num)
    end
    
    def process_hooks_for(repo_subdomain, repo_path, revision)
      repo         = find_repo(repo_subdomain)
      hook_options = indexed_hooks(hooks_for(repo))
      Warehouse::Hooks::Commit.run repo, repo_path, revision, hook_options
    end

    def write_repo_users_to_htpasswd(repo_subdomain, htpasswd_path)
      repo = find_repo(repo_subdomain)
      if repo.nil?
        puts "No repository found for '#{repo_subdomain}'", :warn
        return
      end
      write_users_to_htpasswd(users_from_repo(repo), htpasswd_path.gsub(/:repo/, base_path(repo[:path])))
    end
    
    def write_users_to_htpasswd(users, htpasswd_path = nil)
      if htpasswd_path.nil?
        htpasswd_path = users
        users         = connection[:users]
      end
      
      users = users.select(:login, :crypted_password) if users.is_a?(Sequel::Dataset)
      open htpasswd_path, 'w' do |f|
        users.each do |user|
          next if user[:login].to_s == '' || user[:crypted_password].to_s == ''
          f.write("%s:%s\n" % [user[:login], user[:crypted_password]])
        end
      end
      puts "Wrote htpasswd file to '#{htpasswd_path}'"
    end

    def build_config_for(repositories, config_path)
      if repositories.nil? 
        build_config_for connection[:repositories], config_path
        return
      end
      
      unless repositories.is_a?(Sequel::Dataset) || repositories.is_a?(Array)
        return build_config_for([find_repo(repositories)], config_path)
      end

      permissions = grouped_permission_paths_for(repositories)
      users = indexed_users_from(permissions.values.collect { |index| index.values }.flatten)
      
      open config_path, 'w' do |file|
        file.write SvnAccessBuilder.new(repositories, permissions, users).render
      end
      puts "Wrote access config file to '#{config_path}'"
    end

    # Uses active record!
    def import_users_from_htpasswd(htpasswd, email_domain = nil, repo = nil, repo_path = nil, repo_access = false)
      repo = find_repo(repo) unless repo.nil? || repo.is_a?(Repository)
      email_domain ||= 'unknown.net'
      User.transaction do
        IO.read(htpasswd).split("\n").each do |line|
          line.strip!
          login, password = line.split(":")
          user = User.new(:login => login)
          user.crypted_password = password
          user.email = "#{login}@#{email_domain}"
          i = 1
          user.login = "#{login}_#{i+=1}" until user.valid?
          user.save!
          
          next if repo.nil? || repo_path.nil?
          repo.grant(:path => repo_path, :user => user, :full_access => repo_access)
        end
      end
    end
    
    def clear_changesets
      clear_changesets_for nil
    end
    
    def clear_changesets_for(repo_subdomain)
      repo = repo_subdomain && find_repo(repo_subdomain)
      if repo_subdomain && repo.nil?
        puts "No repo(s) found, REPO=#{repo_subdomain.inspect} given."
        return
      end
      changesets = connection[:changesets]
      changes    = connection[:changes]
      repos      = connection[:repositories]
      if repo
        changesets = changesets.where(:repository_id => repo[:id]) 
        changes    = changes.where(:changeset_id => changesets.select(:id))
      end
      connection.transaction do
        [changes, changesets].each { |ds| ds.delete }
        (repo || repos).update :synced_changed_at => nil, :synced_revision => nil, :changesets_count => 0
      end
      puts repo ? "All revisions for #{repo[:name].inspect} were cleared." : "All revisions for all repositories were cleared"
    end
      
    def repos_from_user(user)
      user = connection[:users][:id => user] unless user.is_a?(Hash)
      repository_ids = connection[:permissions].select(:repository_id).where(:user_id => user[:id]).uniq
      connection[:repositories].where :id => repository_ids
    end
    
  protected
    def find_repo(value)
      case value
        when Hash, Sequel::Dataset, NilClass then value
        else
          key   = value.to_i > 0 ? :id : :subdomain
          connection[:repositories][key => value]
      end
    end
    
    def latest_revision_for(repo)
      silo = silo_for(repo)
      silo && silo.latest_revision
    end
    
    def silo_for(repo)
      (@silos ||= {})[repo[:path]] ||= Silo::Repository.new(repo[:scm_type], :path => repo[:path])
    end
    
    def hooks_for(repo)
      connection[:hooks].where(:repository_id => repo[:id], :active => true).order(:name)
    end
    
    def indexed_hooks(hooks)
      hooks.inject [] do |memo, hook|
        memo << [Warehouse::Hooks[hook[:name]], YAML.load(hook[:options])]
      end
    end
    
    def grouped_permissions_for(repositories)
      connection[:permissions].where(:active => 1, :repository_id => repositories.map { |r| r[:id] }).inject({}) do |memo, perm|
        (memo[perm[:repository_id].to_s] ||= []) << perm; memo
      end
    end
    
    def grouped_permission_paths_for(repositories)
      permissions = grouped_permissions_for(repositories)
      permissions.each do |repo_id, perms|
        permissions[repo_id] = perms.inject({}) do |memo, p|
          (memo[p[:path]] ||= []) << p; memo
        end
      end
      permissions
    end
    
    def indexed_users_from(permissions)
      (permissions.any? ? connection[:users].where(:id => permissions.map { |p| p[:user_id] }) : []).inject({}) do |memo, user|
        memo.update user[:id].to_s => user
      end
    end
    
    def users_from_repo(repo)
      user_ids = connection[:permissions].select(:user_id).where(:active => 1, :repository_id => repo[:id]).uniq
      connection[:users].where(:id => user_ids)
    end
    
    def base_path(path)
      path.to_s.split("/").last.to_s
    end
    
    def puts(str, level = :info)
      if level == :raw
        super(str)
      else
        self.class.logger && self.class.logger.send(level, str)
      end
    end
  end
end