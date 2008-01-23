module Silo
  class Node
    class Error < StandardError; end
    include Comparable
    
    @@default_mime_type = 'application/octet-stream'
    @@image_mime_regex  = /(png|jpe?g|gif)/i
    attr_reader :path, :repository

    def initialize(repository, path, revision = nil)
      path.gsub! /(^\/)|(\/$)/, ''
      @repository, @path, @revision = repository, path, revision
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
    
    def node_type
      dir? ? 'dir' : 'file'
    end
    
    def mime_type
      @mime_type ||= @repository.mime_type_for(self)
    end
    
    def text?
      !dir? && mime_type != @@default_mime_type
    end
    
    def image?
      !dir? && (mime_type.to_s =~ @@image_mime_regex || @path =~ @@image_mime_regex)
    end
    
    def child_node_names
      @child_node_names ||= dir? ? @repository.child_node_names_for(self) : []
    end
    
    def blame
      @blame ||= @repository.blame_for(self)
    end
    
    def revision
      @revision ||= @repository.latest_revision_for(self)
    end

    [:author, :message, :changed_at].each do |attr|
      define_method attr do
        instance_variable_get("@#{attr}") || instance_variable_set("@#{attr}", @repository.send("#{attr}_for", self))
      end
    end

    def child_nodes
      if @child_nodes.nil?
        @child_nodes = @repository.child_node_names_for(self).collect do |child_path|
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
      unified_diff_with(revision - 1)
    end
    
    def unified_diff_with(other_rev)
      @repository.unified_diff_for(revision, other_rev.respond_to?(:revision) ? other_rev.revision : other_rev, @path)
    end
    
    def ==(other)
      repository == other.repository &&
        path     == other.path       &&
        revision == other.revision
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
  end
end