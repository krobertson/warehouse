require 'yaml'
require 'cgi'
require 'net/http'

Warehouse::Hooks.define :lighthouse do |hook|
  
  # define the options this hook needs
  hook.option :account, /^[a-z0-9_-]+$/i, 
    "The name of the account used in the URL.  ('activereload' in 'activereload.lighthouseapp.com')"
  hook.option :project, /^\d+$/,
    "Project ID.  ('55'' in '/projects/55/tickets...')"
  hook.option :token,   /^[a-z0-9]+$/i,
    "Unique API Token to identify the user accessing Lighthouse."
  hook.option :users,   /^([a-z0-9_-]+ [a-z0-9]+(,\s*)?)+$/,
    "(Optional) Comma-separated list linking svn commit authors with different Lighthouse tokens.  Examples: 'rick my-token' or 'rick my-token, bob his-token'"
  
  hook.init do
    unless @options[:users].is_a?(Hash)
      user_string = @options.delete(:users).to_s
      @options[:users] = {}
      user_string.split(',').each do |user|
        user.strip!
        next if user.empty?
        name, token = user.split
        @options[:users][name] = token
      end
    end
  end
  
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

  hook.current_token do
    @options[:users][@commit.author] || @options[:token]
  end
  
  hook.changeset_url do
    '%s/projects/%d/changesets.xml?_token=%s' % [@options[:account], @options[:project], current_token]
  end
  
  hook.run do
    Net::HTTP.start "#{@options[:account]}.lighthouseapp.com" do |http|
      http.post changeset_url, changeset_xml
    end
  end
end