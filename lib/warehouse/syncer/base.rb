module Warehouse
  module Syncer
    class Base
      @@extra_change_names      = Set.new(%w(MV CP))
      @@undiffable_change_names = Set.new(%w(D))
      attr_reader :connection, :repo, :num, :silo

      def self.process(connection, repo, silo, num)
        new(connection, repo, silo, num).process
      end

      def initialize(connection, repo, silo, num)
        @connection, @repo, @silo, @num = connection, repo, silo, num
      end
      
      def process
        puts "Syncing #{@num} Revision(s)", :debug
        authors = {}

        yield authors

        unless authors.empty?
          users = @connection[:users].where(:login => authors.keys).inject({}) do |memo, user|
            memo.update(user[:login] => user[:id])
          end
          authors.each do |login, changed_at|
            next unless users[login]
            update_user_activity({:id => users[login], :login => login}, changed_at)
          end
        end
        CacheKey.sweep_cache
      end

    protected
      def update_user_activity(user, changed_at)
        changesets_count = @connection[:changesets].where(:repository_id => @repo[:id], :author => user[:login]).select(:id.COUNT)
        @connection[:permissions].where(:user_id => user[:id], :repository_id => @repo[:id]).update \
          :last_changed_at => changed_at, :changesets_count => changesets_count
      end

      def puts(str, level = :info)
        if level == :raw
          super(str)
        else
          Warehouse::Command.logger && Warehouse::Command.logger.send(level, str)
        end
      end

      def update_repository_progress(revision, changeset, num)
        return if num < 1
        @repo[:changesets_count] = @repo[:changesets_count].to_i + num
        @connection[:repositories].where(:id => @repo[:id]).update :changesets_count => @repo[:changesets_count],
          :synced_changed_at => changeset[:changed_at], :synced_revision => revision
      end

      def create_changeset(revision)
        node      = @silo.node_at('', revision)
        changeset = { 
          :repository_id => @repo[:id],
          :revision      => revision,
          :author        => node.author,
          :message       => node.message,
          :changed_at    => node.changed_at}
        changeset_id   = @connection[:changesets] << changeset
        changes = {:all => [], :diffable => false}
        create_change_from_changeset(node, changeset.update(:id => changeset_id), changes)
        @connection[:changesets].filter(:id => changeset_id).update(:diffable => 1) if changes[:diffable]
        changeset
      end
    
      def create_change_from_changeset(node, changeset, changes)
        (node.added_files).each do |path|
          process_change_path_and_save(node, path, changeset, 'A', changes)
        end
      
        (node.updated_files).each do |path|
          process_change_path_and_save(node, path, changeset, 'M', changes)
        end
      
        deleted_files = node.deleted_files
        moved_files, copied_files  = (node.copied_files).partition do |path|
          deleted_files.delete(path[1])
        end
      
        moved_files.each do |path|
          process_change_path_and_save(node, path, changeset, 'MV', changes)
        end
      
        copied_files.each do |path|
          process_change_path_and_save(node, path, changeset, 'CP', changes)
        end
      
        deleted_files.each do |path|
          process_change_path_and_save(node, path, changeset, 'D', changes)
        end
      end

      def process_change_path_and_save(node, path, changeset, name, changes)
        diff_node = nil
        change = {:changeset_id => changeset[:id], :name => name, :path => path}
        if @@extra_change_names.include?(name)
          change[:path]          = path[0]
          change[:from_path]     = path[1]
          change[:from_revision] = path[2]
          diff_node = @silo.node_at(path[0], node.revision)
        else
          diff_node = @silo.node_at(path, node.revision)
        end
        change[:diffable] = diff_node.text?
        unless @@undiffable_change_names.include?(change[:name]) || changeset[:diffable] == 1
          changes[:diffable] = true if change[:diffable]
        end
        @connection[:changes] << change
      end
    end
  end
end