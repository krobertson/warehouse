require 'yaml'
require 'cgi'
require 'net/http'

Warehouse::Hooks.define :lighthouse do
  # Some common plugin properties
  title    'Lighthouse Beacon'
  author   'activereload'
  version  '1.0'
  homepage 'http://activereload.net'
  notes <<-END_NOTES
    This plugin will post the new revision data to your Lighthouse project.
  END_NOTES
  
  # Define the options this hook needs
  # These are given text fields in the Hook admin for the user to customize them.
  option :account, /^[a-z0-9_-]+$/i, 
    "The name of the account used in the URL.  ('activereload' in 'activereload.lighthouseapp.com')"
  option :project, /^\d+$/,
    "Project ID.  ('55'' in '/projects/55/tickets...')"
  option :token,   /^[a-z0-9]+$/i,
    "Unique API Token to identify the user accessing Lighthouse."
  option :users,   /^([a-z0-9_-]+ [a-z0-9]+(,\s*)?)+$/,
    "Optional comma-separated list linking svn commit authors with different Lighthouse tokens.  (e.g. 'rick ABCDEF12345' or 'rick ABCDEF12345, bob 98765DCBA')"
  
  # Called before #run
  init do
    # accept users value like 'bob token, fred token'
    # converts to hash like {'bob' => 'token', 'fred' => 'token'}
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
  
  # Array of changes like ["M /foo/bar.txt", ...]
  commit_changes do
    @commit.changed.split("\n").inject([]) do |memo, line| 
      if line.strip =~ /(\w)\s+(.*)/
        memo << [$1, $2]
      end
    end
  end

  changeset_xml do
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

  current_token do
    @options[:users][@commit.author] || @options[:token]
  end
  
  changeset_url do
    '%s/projects/%d/changesets.xml?_token=%s' % [@options[:account], @options[:project], current_token]
  end
  
  run do
    Net::HTTP.start "#{@options[:account]}.lighthouseapp.com" do |http|
      http.post changeset_url, changeset_xml
    end
  end
end