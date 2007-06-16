module ActiveReload
  class SheetForm
    @@image_path = "/images/app/btns"
    @@default_images = { :submit => 'save.png', :cancel => 'cancel.png' }
    cattr_accessor :image_path
    cattr_reader   :default_images

    def initialize(template)
      @template = template
      @cancel = @submit = nil
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
    
    def buttons
      @template.content_tag('p',
        cancel_image(*(@cancel ? @cancel : [default_images[:cancel], {}])) +
        submit_image(*(@submit ? @submit : [default_images[:submit], {}])),
        :class => 'btns')
    end

    protected
      def submit_image(img, options = {})
        @template.tag('input', { :type => 'image', :class => 'submit', :src => "/images/app/btns/#{img}" }.merge(options))
      end
      
      def cancel_image(img, options = {})
        @template.image_tag("/images/app/btns/#{img}", {:class => 'imgbtn cancelbtn'}.merge(options))
      end
  end

  module SheetsHelper
    def sheet_form_tag(url_for_options = {}, options = {}, &block)
      concat(form_tag(url_for_options, options), block.binding)
      concat(%(<div class="overlay-form oform">), block.binding)
      sheet_form = SheetForm.new(self)
      yield sheet_form
      concat("</div>", block.binding)
      concat(sheet_form.buttons, block.binding)
      concat("</form>", block.binding)
    end
  end
end