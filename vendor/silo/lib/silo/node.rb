require 'set'
module Silo
  class Node
    class Error < StandardError; end
    include Comparable
    
    @@file_extensions = Set.new(%w(txt rb php python rhtml erb phps phtml shtml html c js json atom xml htm bas css yml))
    @@image_mime_regex  = /(png|jpe?g|gif)/i
    attr_reader :path, :repository

    def initialize(repository, path, revision = nil)
      extend repository.adapter_module::NodeMethods
      self.repository = repository
      self.path       = path
      self.revision   = revision
    end
    
    def name
      @name ||= File.basename(@path) + (self.dir? ? '/' : '')
    end
    
    def paths
      @paths ||= @path.split("/")
    end
    
    def full_path
      @full_path = @repository.full_path_for(self)
    end
    
    def exists?
      @repository.exists?(self)
    end

    def dir?
      @repository.dir?(self)
    end

    def file?
      @repository.file?(self)
    end
    
    def node_type
      dir? ? 'dir' : 'file'
    end
    
    def mime_type
      @mime_type ||= file? ? File.extname(name)[1..-1] : nil
    end
    
    def text?
      return false unless file?
      @@file_extensions.include?(mime_type) || name =~ /^\.?[^\.]+$/
    end
    
    def diffable?
      text? && previous_node.text?
    end
    
    def previous_node
      @previous_node ||= @repository.node_at @path, revision - 1
    end
    
    def image?
      mime_type && mime_type =~ @@image_mime_regex
    end
    
    def child_node_names
      @child_node_names ||= dir? ? @repository.child_node_names_for(self) : []
    end
    
    def blame
      return nil unless file?
      @blame ||= @repository.blame_for(self)
    end
    
    def revision
      @revision ||= begin
        @latest   = true
        @repository.latest_revision
      end
    end

    def latest?
      (@latest ||= revision == latest_revision || :false) != :false
    end

    [:author, :message, :changed_at, :latest_revision, :child_node_names].each do |attr|
      define_method attr do
        instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", @repository.send("#{attr}_for", self))
      end
    end

    def child_nodes
      if @child_nodes.nil?
        @child_nodes = child_node_names.collect do |child_path|
          self.class.new(@repository, @path.size.zero? ? child_path : File.join(@path, child_path))
        end
        @child_nodes.sort!
      end
      @child_nodes
    end
    
    def content(&block)
      @repository.content_for self, &block
    end
    
    def unified_diff
      unified_diff_with nil
    end
    
    def unified_diff_with(other_rev = nil)
      args = (other_rev ? [revision, other_rev] : [other_rev, revision]) << @path
      @repository.unified_diff_for(*args)
    end
    
    def ==(other)
      other.respond_to?(:repository) && repository == other.repository &&
        other.respond_to?(:path)     && path       == other.path       &&
        other.respond_to?(:revision) && revision   == other.revision
    end
    
    def <=>(other)
      if (dir? && other.dir?) || (!dir? && !other.dir?)
        name <=> other.name
      elsif dir?
        -1
      else
        1
      end
    end

  protected
    def repository=(value)
      @repository = value
    end
    
    def path=(value)
      @path = value.gsub /(^\/)|(\/$)/, ''
    end
    
    def revision=(value)
      @revision = value
    end
  end
end