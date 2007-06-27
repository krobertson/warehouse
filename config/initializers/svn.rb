require 'svn/core'
require 'svn/repos'
require 'svn/delta'
require 'svn/client'
require 'svn/wc'

class Svn::Delta::ChangedEditor
  def add_file_with_collection(*args)
    @dirty_run_count = @dirty_run_count ? @dirty_run_count + 1 : 0
    GC.start if (@dirty_run_count % 20).zero?
    add_file_without_collection(*args)
  end
  
  alias_method :add_file_without_collection, :add_file
  alias_method :add_file, :add_file_with_collection
end

module Svn
  module Fs
    class FileSystem
      @@gc_count = 0

      def root_with_gc(rev=nil)
        @@gc_count = (@@gc_count + 1) % 20
        GC.start if @@gc_count.zero?
        root_without_gc(rev)
      end      
      alias_method :root_without_gc, :root      
      alias_method :root, :root_with_gc
    end
  end
end