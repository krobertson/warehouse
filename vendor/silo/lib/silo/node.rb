module Silo
  class Node
    include Comparable
    
    attr_reader :path, :repository

    def initialize(repository, path, revision = nil)
      path.gsub! /(^\/)|(\/$)/, ''
      @repository, @path, @revision = repository, path, revision
    end
    
    def name
      @name ||= File.basename(@path) << (self.dir? ? '/' : '')
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
    
    def mime_type
      @mime_type ||= @repository.mime_type_for(self)
    end
    
    def text?
      mime_type.to_s =~ /te?xt/i
    end
    
    def image?
      mime_type.to_s =~ /(png|jpe?g|gif)/i
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
    
    def content
      @repository.content_for self
    end
    
    def unified_diff
      unified_diff_with(Node.new(@repository, @path, revision-1))
    end
    
    def unified_diff_with(other)
      @repository.unified_diff_for(self, other)
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