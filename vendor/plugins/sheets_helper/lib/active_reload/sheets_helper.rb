module ActiveReload
  class SheetFormBuilder < ActionView::Helpers::FormBuilder
    @@image_path = "/images/app/btns"
    @@default_images = { :submit => 'save.png', :cancel => 'cancel.png' }
    cattr_accessor :image_path
    cattr_reader   :default_images

    def initialize(object_name, object, template, options, proc)
      super
      @hidden_fields = []
      @cancel = @submit = nil
    end

    (field_helpers - %w(check_box radio_button fields_for hidden_field)).each do |selector|
      src = <<-end_src
        def #{selector}(label, method, options = {})
          return nil if @object_name.nil?
          @template.content_tag('p', @template.content_tag('label', label, :for => "\#{@object_name}_\#{method}") + super(method, options))
        end
      end_src
      class_eval src, __FILE__, __LINE__
    end

    def cancel(value, options = {})
      @cancel = [value, options]
    end
    
    def submit(value, options = {})
      @submit = [value, options]
    end

    def text_field_tag(label, id, value, options = {})
      @template.content_tag('p', 
        @template.content_tag('label', label, :for => id) +
        @template.text_field_tag(id, value, options))
    end
    
    def check_box(label, desc, method, options = {}, checked_value = "1", unchecked_value = "0")
      @template.content_tag('p', 
        @template.content_tag('label', label, :for => "\#{@object_name}_\#{method}") +
        super(method, options, checked_value, unchecked_value) + ' ' + 
        desc)
    end
    
    def hidden_field(method, options = {})
      @hidden_fields << super
    end
    
    def buttons
      hidden = @hidden_fields.any? ? @hidden_fields.join("\n") : ''
      @template.content_tag('p',
        hidden + 
        cancel_image(*(@cancel ? @cancel : [default_images[:cancel], {}])) +
        submit_image(*(@submit ? @submit : [default_images[:submit], {}])),
        :class => 'btns')
    end

    protected
      def submit_image(img, options = {})
        @template.tag('input', { :type => 'image', :class => 'submit', :src => "/images/app/btns/#{img}" }.merge(options))
      end
      
      def cancel_image(img, options = {})
        @template.image_tag("/images/app/btns/#{img}", {:class => 'cancelbtn'}.merge(options))
      end
  end

  module SheetsHelper
    def cache_current_sheets(*default_sheets)
      sheets = default_sheets + @current_sheets.to_a
      return if sheets.blank?
      sheets.collect do |s| 
        "Sheet.Cache['#{escape_javascript s.first}'] = new Sheet('#{escape_javascript s.first}', '#{escape_javascript s.last.to_s}');"
      end.join("\n")
    end

    def sheet_form_tag(url_for_options = {}, options = {}, &block)
      concat(form_tag(url_for_options, options), block.binding)
      sheet_form_helper(options, &block)
    end

    def sheet_form_for(record_or_name, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      
      case record_or_name
        when String, Symbol
          object_name = record_or_name
          object      = args.first
        else
          object      = record_or_name
          object_name = ActionController::RecordIdentifier.singular_class_name(record_or_name)
          apply_form_for_options!(object, options)
          args.unshift object
      end
      concat(form_tag(options.delete(:url), options[:html]), block.binding)
      sheet_form_helper(options, SheetFormBuilder.new(object_name, object, self, options, block), &block)
    end

    def remote_sheet_form_tag(options = {}, &block)
      concat(form_remote_tag(options), block.binding)
      sheet_form_helper(options, &block)
    end
    
    def remote_sheet_form_for(record_or_name, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      
      case record_or_name
        when String, Symbol
          object_name = record_or_name
          object      = nil
        else
          object      = record_or_name
          object_name = ActionController::RecordIdentifier.singular_class_name(record_or_name)
          apply_form_for_options!(object, options)
          args.unshift object
      end
      concat(form_remote_tag(options), block.binding)
      sheet_form_helper(options, SheetFormBuilder.new(object_name, object, self, options, block), &block)
    end
    
    private
      def sheet_form_helper(options = {}, sheet_form = nil, &block)
        id = options[:html] ? options[:html][:id] : options[:id]
        (@current_sheets ||= []) << [id, options.delete(:trigger)].compact if id
        concat(%(<div class="overlay-form oform">), block.binding)
        sheet_form ||= SheetFormBuilder.new(nil, nil, self, options, block)
        yield sheet_form
        concat("</div>", block.binding)
        concat(sheet_form.buttons, block.binding)
        concat("</form>", block.binding)
      end
  end
end