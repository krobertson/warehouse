class Change < ActiveRecord::Base
  attr_accessor :orig_path
  validates_presence_of :changeset_id, :name

  belongs_to :changeset
  delegate :revision, :to => :changeset
  attr_accessible :path, :name, :orig_path

  before_save :process_orig_path_info

  def self.create_from_changeset(changeset)
    root           = changeset.backend.fs.root(changeset.revision)
    base_root      = changeset.backend.fs.root(changeset.revision-1)
    changed_editor = Svn::Delta::ChangedEditor.new(root, base_root)
    base_root.dir_delta('', '', root, '', changed_editor)
    
    (changed_editor.added_dirs + changed_editor.added_files).each do |path|
      changeset.changes.create!(:name => 'A', :path => path)
    end
    
    (changed_editor.updated_dirs + changed_editor.updated_files).each do |path|
      changeset.changes.create!(:name => 'M', :path => path)
    end
    
    deleted_files = changed_editor.deleted_dirs + changed_editor.deleted_files
    moved_files, copied_files  = (changed_editor.copied_dirs  + changed_editor.copied_files).partition do |path|
      deleted_files.delete(path[1])
    end

    moved_files.each do |path|
      changeset.changes.create!(:name => 'MV', :orig_path => path)
    end
    
    copied_files.each do |path|
      changeset.changes.create!(:name => 'CP', :orig_path => path)
    end

    deleted_files.each do |path|
      changeset.changes.create!(:name => 'D', :path => path)
    end
  end
  
  def backend
    changeset.repository.backend
  end
  
  protected
    def process_orig_path_info
      case name
        when 'MV', 'CP'
          self.path          = orig_path[0]
          self.from_ath      = orig_path[1]
          self.from_revision = orig_path[2]
      end
      @orig_path = nil
      true
    end
end
