module Warehouse
  class PluginBase
    attr_reader :options

    def initialize(options = {}, &block)
      @options = default_options.dup
      options.each do |key, value|
        send "#{key}=", value
      end
      block.call(self) if block
    end

    class << self
      def plugin_name
        @plugin_name ||= underscore(demodulize(name))
      end
    
      def class_name_of(plugin_name)
        camelize plugin_name
      end

      plugin_property_source = %w(title author version homepage notes).collect! do |property|
        <<-END
          def #{property}(value = nil)
            @#{property} = value.to_s.strip if value
            @#{property}
          end
        END
      end
      eval plugin_property_source * "\n"

      def default_options
        @default_options ||= {}
      end
      
      def option_formats
        @option_formats ||= {}
      end
      
      def option_order
        @option_order ||= []
      end

      def option(property, *args)
        desc    = args.pop
        format  = args.first.is_a?(Regexp) ? args.shift : nil
        default = args.shift
        class_eval <<-END, __FILE__, __LINE__
            def #{property}
              options[:#{property}].to_s.empty? ? #{default.inspect} : options[:#{property}]
            end
          
            def #{property}=(value)
              options[:#{property}] = value#{" if value.to_s =~ #{format.inspect}" if format}
            end
          END
        option_order << "#{property} #{desc}".strip
        default_options[property.to_sym] = default
        option_formats[property.to_sym]  = format if format
      end
      
      def valid_options?(options)
        options.each do |key, value|
          if format = option_formats[key.to_sym]
            return false unless value.blank? || value.to_s =~ format
          end
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

    # assume activesupport is not available
    private
      def camelize(lower_case_and_underscored_word)
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      end

      def demodulize(modulized)
        modulized.to_s.gsub(/^.+::/, '')
      end

      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    plugin_property_source = %w(title author version homepage notes plugin_name plugin_path view_path default_options option_formats option_order valid_options?).collect! do |property|
      "def #{property}(*args) self.class.#{property}(*args) end"
    end
    eval plugin_property_source * "\n"

    def self.logger
      RAILS_DEFAULT_LOGGER
    end

    def logger
      RAILS_DEFAULT_LOGGER
    end
  end
end