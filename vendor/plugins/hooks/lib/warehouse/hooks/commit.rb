module Warehouse
  module Hooks
    class Commit
      class << self
        attr_accessor :svnlook_path

        def run(repo_path, revision, hook_options)
          commit = new(repo_path, revision)
          hook_options.each do |(hook_class, options)|
            hook = hook_class.new(commit, options)
            hook.run! if hook.valid?
          end
        end

        # see expiring_attr_reader plugin
        def expiring_attr_reader(method_name, value)
          var_name    = method_name.to_s.gsub(/\W/, '')
          class_eval(<<-EOS, __FILE__, __LINE__)
            def #{method_name}
              def self.#{method_name}; @#{var_name}; end
              @#{var_name} ||= eval(%(#{value}))
            end
          EOS
        end
      end
      
      %w(author dirs_changed log changed).each do |attr|
        expiring_attr_reader attr, "retrieving_#{attr}"
      end
      
      self.svnlook_path = '/usr/bin/svnlook'
      
      def initialize(repo_path, revision)
        @repo_path = repo_path
        @revision  = revision
      end
      
      protected
        def retrieving_author
          svnlook :author
        end
        
        def retrieving_dirs_changed
          svnlook 'dirs-changed'
        end
        
        def retrieving_log
          svnlook :log
        end
        
        def retrieving_changed
          svnlook :changed
        end
        
        def svnlook(cmd)
          `#{self.class.svnlook_path} #{cmd} #{@repo_path} -r #{@revision}`.strip
        end
    end
  end
end