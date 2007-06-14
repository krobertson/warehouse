module Importer
  module MysqlAdapter
    class Change < Base
      table 'changes'
      
      def self.create_from_changeset(repository, changeset)
        root           = repository.backend.fs.root(changeset.attributes['revision'].to_i)
        base_root      = repository.backend.fs.root(changeset.attributes['revision'].to_i-1)
        changed_editor = Svn::Delta::ChangedEditor.new(root, base_root)
        base_root.dir_delta('', '', root, '', changed_editor)
        
        (changed_editor.added_dirs + changed_editor.added_files).each do |path|
          create(changeset, 'A', path)
        end
        
        (changed_editor.updated_dirs + changed_editor.updated_files).each do |path|
          create(changeset, 'M', path)
        end
        
        deleted_files = changed_editor.deleted_dirs + changed_editor.deleted_files
        moved_files, copied_files  = (changed_editor.copied_dirs  + changed_editor.copied_files).partition do |path|
          deleted_files.delete(path[1])
        end
        
        moved_files.each do |path|
          create(changeset, 'MV', path)
        end
        
        copied_files.each do |path|
          create(changeset, 'CP', path)
        end
        
        deleted_files.each do |path|
          create(changeset, 'D', path)
        end
      end
      
      def self.create(changeset, name, path)
        columns = %w(changeset_id name path)
        values  = [changeset.attributes['id'], name, path]
        if name =~ /MV|CP/
          columns << 'from_path' << 'from_revision' 
          values.pop
          values  << path[0] << path[1] << path[2]
        end
        insert(columns, values)
      end
    end
  end
end