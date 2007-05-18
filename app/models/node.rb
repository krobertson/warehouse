class Node
  @@default_mime_type = 'application/octet-stream'
  attr_reader :base_revision
  attr_reader :path
  attr_reader :repository
  delegate :backend, :to => :repository
  
  def initialize(repository, path, rev = nil)
    @repository    = repository
    @path          = path
    @base_revision = rev || repository.latest_revision
  end

  def changeset
    @changeset ||= repository.changesets.find_by_revision(revision)
  end

  def node_type
    self.dir? ? 'Dir' : 'File'
  end

  def child_nodes
    @child_nodes ||= self.child_node_names.collect do |name|
      self.class.new(repository, path.blank? ? name : File.join(path, name), base_revision)
    end.sort_by { |node| [node.node_type, node.name.downcase] }
  end

  def child_node_names
    @child_node_names ||= self.dir? ? root.dir_entries(path).keys : []
  end

  def revision
    @revision ||= root.node_created_rev(path)
  end

  def author
    @author ||= prop(Svn::Core::PROP_REVISION_AUTHOR).to_s
  end
  
  def changed_at
    @changed_at ||= prop(Svn::Core::PROP_REVISION_DATE)
  end
    
  def message
    @message ||= prop(Svn::Core::PROP_REVISION_LOG)
  end

  def type_code
    @type_code ||= root.check_path(path)
  end

  def dir?
    type_code == Svn::Core::NODE_DIR
  end
              
  def exists?
    type_code != Svn::Core::NODE_NONE
  end
          
  def name
    File.basename(path) + (self.dir? ? '/' : '')
  end

  def paths
    path.split('/')
  end

  def text?
    return false unless mime_type
    @textual_type ||= self.mime_type =~ /^text/i
  end
    
  def image?
    return false unless mime_type
    @image_type ||= self.mime_type =~ /image\/(png|jpg|jpeg|gif)/i
  end

  def svn_mime_type
    @svn_mime_type ||= self.dir? ? nil : root.node_prop(path, Svn::Core::PROP_MIME_TYPE)
  end

  def mime_type
    return nil if self.dir? || !self.exists?
  
    if svn_mime_type.blank? || svn_mime_type == @@default_mime_type
      file_type = File.extname(self.name).gsub(/^\./, '')
      file_type = self.name if file_type.blank?
      file_type && MIME_TYPE_MAP[file_type] ? MIME_TYPE_MAP[file_type] : @@default_mime_type
    else
      svn_mime_type
    end      
  end

  protected
    def root
      @root ||= backend.fs.root(base_revision)
    end

    def prop(const, rev = nil)
      backend.fs.prop(const, rev || revision)
    end

    def previous_root
      @previous_root ||= backend.fs.root(base_revision - 1)
    end
end