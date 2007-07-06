require 'svn/core'
require 'svn/repos'
require 'svn/delta'
require 'svn/client'
require 'svn/wc'

# SVN Manual Garbage Collection
# http://retrospectiva.org/browse/trunk/lib/patches.rb?format=txt&rev=141
module Svn
  @@dirty_runs = 0
  def self.sweep_garbage!
    GC.start if (@@dirty_runs = (@@dirty_runs + 1) % 10).zero?
  end 

  module Fs
    class FileSystem
      def root_with_gc(rev = nil)
        Svn.sweep_garbage!
        root_without_gc(rev)
      end      
      alias_method :root_without_gc, :root
      alias_method :root, :root_with_gc
    end

    class Root
      def copied_from_with_gc(*args)
        Svn.sweep_garbage!
        copied_from_without_gc(*args)
      end
      alias_method :copied_from_without_gc, :copied_from
      alias_method :copied_from, :copied_from_with_gc

      def close_with_gc
        ret = close_without_gc
        Svn.sweep_garbage!
        ret
      end
      alias_method :close_without_gc, :close
      alias_method :close, :close_with_gc

      def file_contents_with_gc(*args, &block)
        Svn.sweep_garbage!
        file_contents_without_gc(*args, &block)
      end
      alias_method :file_contents_without_gc, :file_contents
      alias_method :file_contents, :file_contents_with_gc
    end
  end

  module Delta
    class ChangedEditor
      def add_file_with_gc(*args)
        Svn.sweep_garbage!
        add_file_without_gc(*args)
      end
      
      alias_method :add_file_without_gc, :add_file
      alias_method :add_file, :add_file_with_gc
    end
  end
end