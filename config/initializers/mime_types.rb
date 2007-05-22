# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile
Mime::Type.register 'text/plain', :diff

CSS_CLASSES = {}
%w(.rb).each { |e| CSS_CLASSES[e] = :script }