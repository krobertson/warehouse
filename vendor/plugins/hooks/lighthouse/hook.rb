require 'yaml'
require 'cgi'
require 'net/http'

Warehouse::Hooks.define :lighthouse do |hook|
  hook.commit_changes do
    @commit.changed.split("\n").inject([]) do |memo, line| 
      if line.strip =~ /(\w)\s+(.*)/
        memo << [$1, $2]
      end
    end
  end

  hook.changeset_xml do
    <<-END_XML
<changeset>
  <title>#{CGI.escapeHTML("%s committed changeset [%d]" % [@commit.author, @commit.revision])}</title>
  <body>#{CGI.escapeHTML(@commit.log)}</body>
  <changes>#{CGI.escapeHTML(commit_changes.to_yaml)}</changes>
  <revision>#{CGI.escapeHTML(@commit.revision.to_s)}</revision>
  <changed-at type="datetime">#{CGI.escapeHTML(@commit.date.split('(').first.strip)}</changed-at>
</changeset>
END_XML
  end

  hook.token do
    @options[:users][@commit.author] || @options[:token]
  end
  
  hook.url do
    '%s/projects/%d/changesets.xml?_token=%s' % [@options[:account], @options[:project], token]
  end
  
  hook.run do
    url = '%s/projects/%d/changesets.xml?_token=%s' % [@options[:account], @options[:project], token]
  end
end