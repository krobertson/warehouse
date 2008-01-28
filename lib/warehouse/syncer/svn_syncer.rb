module Warehouse
  module Syncer
    class SvnSyncer < Base
      @@extra_change_names      = Set.new(%w(MV CP))
      @@undiffable_change_names = Set.new(%w(D))

      def process
        super do |authors|
          latest_changeset = @connection[:changesets].where(:repository_id => @repo[:id]).order(:changed_at.DESC).first
          recorded_rev     = latest_changeset[:revision].to_i
          latest_rev       = @silo.latest_revision
          @connection.transaction do    
            i = 0
            rev = recorded_rev + 1 
            until rev >= latest_rev || i >= @num do
              if i > 1 && i % 100 == 0
                @connection.execute "COMMIT"
                @connection.execute "BEGIN"
                puts "##{rev}", :debug
              end
              changeset = create_changeset(rev)
              authors[changeset[:author]] = changeset[:changed_at]
              i   += 1
              rev += 1
            end
          end
        end
      end

    protected
      def create_changeset(revision)
        node      = @silo.node_at('', revision)
        changeset = { 
          :repository_id => @repo[:id],
          :revision      => revision,
          :author        => node.author,
          :message       => node.message,
          :changed_at    => node.changed_at}
        changeset_id   = @connection[:changesets] << changeset
        changes = {:all => [], :diffable => []}
        create_change_from_changeset(node, changeset.update(:id => changeset_id), changes)
        @connection[:changesets].filter(:id => changeset_id).update(:diffable => 1) if changes[:diffable].size > 0
        changeset
      end
    
      def create_change_from_changeset(node, changeset, changes)
        (node.added_directories + node.added_files).each do |path|
          process_change_path_and_save(node, changeset, 'A', path, changes)
        end
      
        (node.updated_directories + node.updated_files).each do |path|
          process_change_path_and_save(node, changeset, 'M', path, changes)
        end
      
        deleted_files = node.deleted_directories + node.deleted_files
        moved_files, copied_files  = (node.copied_directories  + node.copied_files).partition do |path|
          deleted_files.delete(path[1])
        end
      
        moved_files.each do |path|
          process_change_path_and_save(node, changeset, 'MV', path, changes)
        end
      
        copied_files.each do |path|
          process_change_path_and_save(node, changeset, 'CP', path, changes)
        end
      
        deleted_files.each do |path|
          process_change_path_and_save(node, changeset, 'D', path, changes)
        end
      end

      def process_change_path_and_save(node, changeset, name, path, changes)
        change = {:changeset_id => changeset[:id], :name => name, :path => path}
        if @@extra_change_names.include?(name)
          change[:path]          = path[0]
          change[:from_path]     = path[1]
          change[:from_revision] = path[2]
        end
        unless @@undiffable_change_names.include?(change[:name]) || changeset[:diffable] == 1
          changes[:diffable] << change unless node.mime_type == 'application/octet-stream'
        end
        changes[:all] << change
        @connection[:changes] << change
      end
    end
  end
end