require 'yaml'
require 'cgi'
require 'net/http'

Warehouse::Hooks.define :lighthouse do
  commit_changes = @commit.changed.split("\n").inject([]) do |memo, line| 
    if line.strip =~ /(\w)\s+(.*)/
      memo << [$1, $2]
    end
  end.to_yaml

  changeset_xml = <<-END_XML
<changeset>
<title>#{CGI.escapeHTML("%s committed changeset [%d]" % [@commit.author, @commit.revision])}</title>
<body>#{CGI.escapeHTML(@commit.log)}</body>
<changes>#{CGI.escapeHTML(commit_changes)}</changes>
<revision>#{CGI.escapeHTML(@commit.revision.to_s)}</revision>
<changed-at type="datetime">#{CGI.escapeHTML(@commit.date.split('(').first.strip)}</changed-at>
</changeset>
END_XML

  token = @options[:users][@commit.author] || @options[:token]
  url = '%s/projects/%d/changesets.xml?_token=%s' % [@options[:account], @options[:project], token]
end