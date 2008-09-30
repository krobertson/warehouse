# adapted from retrospectiva
# http://retrospectiva.org/browse/trunk/app/models/repository_node.rb?rev=141
class Node
  class Error < StandardError; end
  include PathAccessibility
  @@default_mime_type = 'application/octet-stream'
  attr_reader :base_revision
  attr_reader :path
  attr_reader :repository
  delegate :backend, :to => :repository
  
  def initialize(repository, path, rev = nil)
    @repository    = repository
    @path          = path
    @base_revision = rev.nil? ? repository.latest_revision : rev.to_i
  end
  
  def blame
    @blame ||= begin
      lines = {:username_length => 0}
      client.blame("file://#{File.join repository.path, path}", 1, base_revision) do |num, rev, username, changed_at, line|
        lines[num+1] = [rev, username]
        lines[:username_length] = [lines[:username_length], username.length].max
      end
      lines
    end
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
    @revision ||= exists? ? root.node_created_rev(path) : 0
  end

  def author
    @author ||= exists? ? prop(Svn::Core::PROP_REVISION_AUTHOR).to_s : ''
  end
  
  def changed_at
    @changed_at ||= exists? ? prop(Svn::Core::PROP_REVISION_DATE) : nil
  end
    
  def message
    @message ||= exists? ? prop(Svn::Core::PROP_REVISION_LOG) : ''
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
  
  def diffable?
    text? && previous_root.check_path(path) == Svn::Core::NODE_FILE
  end
          
  def name
    File.basename(path) + (self.dir? ? '/' : '')
  end

  def paths
    path.split('/')
  end

  def text?
    return false unless mime_type
    @text_type ||= self.svn_mime_type != @@default_mime_type
  end
    
  def image?
    return false unless mime_type
    @image_type ||= self.mime_type =~ /(png|jpg|jpeg|gif)/i
  end

  def svn_mime_type
    @svn_mime_type ||= self.dir? ? nil : root.node_prop(path, Svn::Core::PROP_MIME_TYPE)
  end

  def mime_type
    return nil if self.dir? || !self.exists?
  
    if svn_mime_type.blank? || svn_mime_type == @@default_mime_type
      File.extname(self.name).gsub(/^\./, '')
    else
      svn_mime_type
    end      
  end

  def content
    return if self.dir? || !self.exists?
    unless @content
      content = root.file_contents(self.path) do |s|
        returning(s.read) { |rs| GC.start }
      end      
      content_charset = 'utf-8'
      unless self.mime_type.blank?
        content_charset = self.mime_type.slice(%r{charset=([A-Za-z0-9\-_]+)}, 1) || content_charset
      end
      @content = convert_to_utf8(content, content_charset)          
    end
    @content
  end

  def unified_diff
    unless @unified_diff || !text?
      @unified_diff = unified_diff_for previous_root, root, path
    end
    @unified_diff
  end

  def unified_diff_for(old_rev, new_rev, diff_path)
    old_rev  = find_revision old_rev, diff_path
    new_rev  = find_revision new_rev, diff_path
    sorted   = check_revisions(old_rev, new_rev)
    old_root = find_root_for_revision(sorted[0], diff_path)
    new_root = find_root_for_revision(sorted[1], diff_path)
    
    differ = Svn::Fs::FileDiff.new(old_root, diff_path, new_root, diff_path)

    if differ.binary?
      ''
    else
      old = "#{diff_path} (revision #{old_root.node_created_rev(diff_path)})"
      cur = "#{diff_path} (revision #{new_root.node_created_rev(diff_path)})"
      differ.unified(old, cur)
    end
  end
  
  def find_root_for_revision(rev, diff_path)
    return rev           if rev.respond_to?(:node_prop)
    return root          if rev ==  base_revision
    return previous_root if rev == (base_revision - 1)
    backend.fs.root find_revision(rev, diff_path)
  end
  
  def find_revision(rev, diff_path)
    return rev.node_created_rev(diff_path) if rev.respond_to?(:node_created_rev)
    case rev
      when /^\d+$/
        rev.to_i
      when Date
        changeset = repository.changesets.find_by_date_for_path(rev, diff_path)
        changeset ? changeset.revision.to_i : nil
      when Fixnum
        rev
      when String
        rev
      else raise Error, "Invalid Revision: #{rev.inspect}"
    end
  end
  
  def check_revisions(old_rev, new_rev)
    if old_rev.is_a?(String) && new_rev.is_a?(String)
      raise Error, "Can't have two relative revisions: #{old_rev.inspect} - #{new_rev.inspect}"
    end
    
    if old_rev.is_a?(String)
      old_rev = relative_revision_to(new_rev, old_rev)
    elsif new_rev.is_a?(String)
      new_rev = relative_revision_to(old_rev, new_rev)
    end
    
    unless old_rev.is_a?(Fixnum) && new_rev.is_a?(Fixnum)
      raise Error, "Can't have two non-integer revisions: #{old_rev.inspect} - #{new_rev.inspect}"
    end
    [old_rev, new_rev]
  end
  
  def relative_revision_to(revision, value)
    case value
      when /^h/i
        repository.latest_revision
      when /^p/i
        revision - 1
      when /^n/i
        revision < repository.latest_revision ? (revision + 1) : revision
      else
        nil
    end
  end

  def root
    @root ||= backend.fs.root(base_revision)
  end

  def prop(const, rev = nil)
    backend.fs.prop(const, rev || revision)
  end

  def previous_root
    @previous_root ||= backend.fs.root(base_revision - 1)
  end

  def convert_to_utf8(content, content_charset)
    return content if content_charset == 'utf-8'
    Iconv.conv('utf-8', content_charset, content) rescue content
  end
  
  def client
    @client ||= Svn::Client::Context.new
  end
end