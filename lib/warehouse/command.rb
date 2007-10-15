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
      unless backend_for(repo)
        puts "No SVN repository found for '#{repo[:subdomain]}' in '#{repo[:path]}'", :warn
        return
      end

      revisions = paginated_revisions(repo, num)
      connection.transaction do
        authors = {}
        puts "Syncing Revisions ##{revisions.first} - ##{revisions.last}", :debug
        
        revisions.each do |rev|
          if rev > 1 && rev % 100 == 0
            connection.execute "COMMIT"
            connection.execute "BEGIN"
            puts "##{rev}", :debug
          end
          changeset = create_changeset(repo, rev)
          authors[changeset[:author]] = Time.now.utc
        end
        users = connection[:users].where(:login => authors.keys).inject({}) do |memo, user|
          memo.update(user[:login] => user[:id])
        end
        
        authors.each do |login, changed_at|
          next unless users[login]
          update_user_activity repo, {:id => users[login], :login => login}, changed_at
        end
        CacheKey.sweep_cache
        puts revisions.last, :raw
      end unless revisions.empty?
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
        repositories.each do |repo|
          perms_hash = permissions[repo[:id].to_s]
          next if perms_hash.nil?
          perms_hash.each do |path, perms|
            file.write("[%s:/%s]\n" % [base_path(repo[:path]), path])
            perms.each do |p|
              if p[:user_id].nil?
                file.write('*')
              else
                login = users[p[:user_id].to_s][:login] rescue nil
                next if login.nil? || login.size == 0
                file.write(login)
              end
              file.write(' = r')
              file.write('w') if p[:full_access].to_i == 1
              file.write("\n")
            end
            file.write("\n")
          end
        end
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
      repo = repo_subdomain && connection[:repositories].where(:subdomain => repo_subdomain).first
      if repo_subdomain && repo.nil?
        puts "No repo(s) found, REPO=#{repo_subdomain.inspect} given."
        return
      end
      changesets = connection[:changesets]
      changes    = connection[:changes]
      if repo
        changesets = changesets.where(:repository_id => repo) 
        changes    = changes.where(:changeset_id => changesets.select(:id))
      end
      connection.transaction { [changes, changesets].each { |ds| ds.delete } }
      puts repo ? "All revisions for #{repo[:name].inspect} were cleared." : "All revisions for all repositories were cleared"
    end
    
    protected
      def find_repo(value)
        return nil if value.nil?
        return value if value.is_a?(Hash) || value.is_a?(Sequel::Dataset)
        key   = value.to_i > 0 ? :id : :subdomain
        connection[:repositories][key => value]
      end
    
      def paginated_revisions(repo, num)
        revisions = (recorded_revision_for(repo)..latest_revision_for(repo)).to_a
        num > 0 ? revisions[0..num-1] : revisions
      end

      def recorded_revision_for(repo)
        changeset = connection[:changesets].where(:repository_id => repo[:id]).reverse_order(:changed_at).first
        @recorded_revision = (changeset ? changeset[:revision] : 0).to_i + 1
      end

      def latest_revision_for(repo)
        backend = backend_for(repo)
        backend && backend.youngest_rev
      end
    
      def backend_for(repo)
        (@backends ||= {})[repo[:path]] ||= Svn::Repos.open(repo[:path])
      rescue Svn::Error
        nil
      end

      def update_user_activity(repo, user, changed_at)
        changesets_count = connection[:changesets].where(:repository_id => repo[:id], :author => user[:login]).select(:id.COUNT)
        connection[:permissions].where(:user_id => user[:id], :repository_id => repo[:id]).update \
              :last_changed_at => changed_at, :changesets_count => changesets_count
      end
      
      def create_changeset(repo, revision)
        backend = backend_for(repo)
        changeset = { 
          :repository_id => repo[:id],
          :revision      => revision,
          :author        => backend.fs.prop(Svn::Core::PROP_REVISION_AUTHOR, revision),
          :message       => backend.fs.prop(Svn::Core::PROP_REVISION_LOG,    revision),
          :changed_at    => backend.fs.prop(Svn::Core::PROP_REVISION_DATE,   revision).utc}
        changeset_id   = connection[:changesets] << changeset
        changes = {:all => [], :diffable => []}
        create_change_from_changeset(backend, changeset.update(:id => changeset_id), changes)
        connection[:changesets].filter(:id => changeset_id).update(:diffable => 1) if changes[:diffable].size > 0
        changeset
      end
      
      def create_change_from_changeset(backend, changeset, changes)
        root           = backend.fs.root(changeset[:revision].to_i)
        base_root      = backend.fs.root(changeset[:revision].to_i-1)
        changed_editor = Svn::Delta::ChangedEditor.new(root, base_root)
        base_root.dir_delta('', '', root, '', changed_editor)

        (changed_editor.added_dirs + changed_editor.added_files).each do |path|
          process_change_path_and_save(backend, changeset, 'A', path, changes)
        end
        
        (changed_editor.updated_dirs + changed_editor.updated_files).each do |path|
          process_change_path_and_save(backend, changeset, 'M', path, changes)
        end
        
        deleted_files = changed_editor.deleted_dirs + changed_editor.deleted_files
        moved_files, copied_files  = (changed_editor.copied_dirs  + changed_editor.copied_files).partition do |path|
          deleted_files.delete(path[1])
        end
        
        moved_files.each do |path|
          process_change_path_and_save(backend, changeset, 'MV', path, changes)
        end
        
        copied_files.each do |path|
          process_change_path_and_save(backend, changeset, 'CP', path, changes)
        end
        
        deleted_files.each do |path|
          process_change_path_and_save(backend, changeset, 'D', path, changes)
        end
      end
      
      @@extra_change_names = Set.new(%w(MV CP))
      @@undiffable_change_names = Set.new(%w(D))
      def process_change_path_and_save(backend, changeset, name, path, changes)
        change = {:changeset_id => changeset[:id], :name => name, :path => path}
        if @@extra_change_names.include?(name)
          change[:path]          = path[0]
          change[:from_path]     = path[1]
          change[:from_revision] = path[2]
        end
        unless @@undiffable_change_names.include?(change[:name]) || changeset[:diffable] == 1
          root          = backend.fs.root(changeset[:revision])
          mime_type     = root.check_path(change[:path]) == Svn::Core::NODE_DIR ? nil : root.node_prop(change[:path], Svn::Core::PROP_MIME_TYPE)
          changes[:diffable] << change unless mime_type == 'application/octet-stream'
        end
        changes[:all] << change
        connection[:changes] << change
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
      
      def repos_from_user(user)
        user = connection[:users][:id => user] unless user.is_a?(Hash)
        repository_ids = connection[:permissions].select(:repository_id).where(:user_id => user[:id]).uniq
        connection[:repositories].where :id => repository_ids
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