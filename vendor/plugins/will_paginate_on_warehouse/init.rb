WillPaginate::ViewHelpers.module_eval do
  protected
    def link_or_span(page, condition_for_span, span_class = nil, text = page.to_s)
      if condition_for_span
        content_tag :span, text, :class => span_class
      else
        # page links should preserve GET parameters, so we merge params
        link_to text, hosted_url_for(params.merge(:page => (page !=1 ? page : nil), :only_path => true))
      end
    end
end
