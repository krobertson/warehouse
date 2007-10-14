require 'yaml'
require 'cgi'
require 'net/http'

Warehouse::Hooks.define :lighthouse do
  # Some common plugin properties
  title    'Lighthouse Beacon'
  author   'Active Reload LLC.'
  version  '1.0'
  homepage 'http://activereload.net'
  notes <<-END_NOTES
    This hook will post the new revision data to your Lighthouse project.
  END_NOTES
  
  # Define the options this hook needs
  # These are given text fields in the Hook admin for the user to customize them.
  option :account, /^[a-z0-9_-]+$/i, 
    "The account name.  (e.g. 'activereload' in 'activereload.lighthouseapp.com')"
  option :project, /^\d+$/,
    "Project ID.  ('55'' in '/projects/55/tickets...')"
  option :token,   /^[a-z0-9]+$/i,
    "Unique API Token to identify the user accessing Lighthouse."
  option :users,   /^([a-z0-9_-]+ [a-z0-9]+(,\s*)?)+$/,
    "Optional comma-separated list linking svn commit authors with different Lighthouse tokens.  (e.g. 'rick ABCDEF12345, bob 98765DCBA')"
  
  user_tokens do
    options[:users].to_s.split(",").inject({}) do |memo, user|
      user.strip!
      next if user.empty?
      name, token = user.split
      memo.update name => token
    end
  end
  
  # Array of changes like ["M /foo/bar.txt", ...]
  commit_changes do
    commit.changed.split("\n").inject([]) do |memo, line| 
      if line.strip =~ /(\w)\s+(.*)/
        memo << [$1, $2]
      end
    end
  end

  changeset_xml do
    <<-END_XML
<changeset>
  <title>#{CGI.escapeHTML("%s committed changeset [%d]" % [commit.author, commit.revision])}</title>
  <body>#{CGI.escapeHTML(commit.log)}</body>
  <changes>#{CGI.escapeHTML(commit_changes.to_yaml)}</changes>
  <revision>#{CGI.escapeHTML(commit.revision.to_s)}</revision>
  <changed-at type="datetime">#{CGI.escapeHTML(commit.changed_at.xmlschema)}</changed-at>
</changeset>
END_XML
  end

  current_token do
    user_tokens[commit.author] || options[:token]
  end
  
  changeset_url do
    URI.parse('/projects/%d/changesets.xml' % options[:project])
  end
  
  run do
    req = Net::HTTP::Post.new(changeset_url.path) 
    req.basic_auth current_token, 'x' # to ensure authentication
    req.body = changeset_xml.strip
    req.set_content_type('application/xml')
    
    res = Net::HTTP.new("#{options[:account]}.lighthouseapp.com").start {|http| http.request(req) }
    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        ## all good, we submitted...
      else
        if res.code == '422'
          puts "Validation error: #{res.body}"
        else
          raise "#{res.inspect} - #{res.body}"
        end
    end
  end
end