require 'yaml'
require 'cgi'

Warehouse::Hooks.define :email do
  # Some common plugin properties
  title    'Mailer'
  author   'activereload'
  version  '1.0'
  homepage 'http://activereload.net'
  notes <<-END_NOTES
    This plugin emails details of your subversion commits.
    Code adapted from ActiveReload forum user "Joseph": http://forum.activereload.net/forums/7/topics/121
    http://inventivelabs.com.au/
    
    Keep in mind, you will NEED to set your mail settings in the admin/settings area so the
    post-commit mailer knows what to do.
  END_NOTES
  
  option :recipients, "Email address(es) to send to."
  option :sender,     "Email address that the messages are sent from."
  
  first_commit_line do
    commit.log.split("\n").first
  end
  
  extended_commit_lines do
    lines = commit.log.split("\n")[1..-1]
    lines.empty? ? nil : lines
  end
  
  subject do
    "#{commit.revision}: #{first_commit_line}"
  end
  
  body do
    html = []
    html << "<h2>#{commit.revision}: #{CGI.escapeHTML(first_commit_line)}</h2>"
    html << "<p><strong>#{CGI.escapeHTML commit.author.capitalize}</strong> &#8212; " + 
      commit.changed_at.strftime("%I:%M%p, %a %d %b %Y") + "</p>"

    html << "<hr />"
    
    if extended_commit_lines
      html << "<h3>Complete change description:</h3>"
      extended_commit_lines.each do |line|
        html << "<p>#{CGI.escapeHTML(line)}</p>"
      end
    end
    
    html << "<pre>"
    commit.diff.split("\n").each do |line|
      color = nil
      if line.match(/^Modified: /) || line.match(/^Added: /) || line.match(/^=+$/)
        color = "#009"
      elsif line.match(/^\+\+\+/) || line.match(/^---/) || line.match(/^@@ /)
        color = "#999"
      elsif line.match(/^-/)
        color = "#900"
      elsif line.match(/^\+/)
        color = "#390"
      else
        color = "#000"
      end

      html << "<span style=\"color:#{color};\">#{CGI.escapeHTML(line)}</span>"
    end
    html << "</pre>"
    html * "\n"
  end
  
  run do
    msg = Warehouse::Mailer.new :to => options[:recipients], :from => options[:sender], :subject => subject, :html => body
    msg.deliver!
  end
end