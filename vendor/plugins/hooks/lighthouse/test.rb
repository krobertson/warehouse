context "Lighthouse" do
  setup do
    @commit = stub(:revision => 5, :changed => ['M foo', 'A foo/bar'].join("\n"), :author => 'rick', :log => 'add bar', :date => 'abc (def)')
  end
  
  specify "should gather commit changes" do
    Warehouse::Hooks::Lighthouse.new(@commit).commit_changes.should == [%w(M foo), %w(A foo/bar)]
  end
  
  specify "should get use default token if no user token is available" do
    Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test', :users => {}).token.should == 'test'
  end
  
  specify "should get use user token if available" do
    Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test', :users => {'rick' => 'foo'}).token.should == 'foo'
  end
  
  specify "should construct url from options" do
    Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test', :users => {}, :account => 'a', :project => '1').url.should == "a/projects/1/changesets.xml?_token=test"
  end
  
  specify "should construct changeset xml" do
    hook = Warehouse::Hooks::Lighthouse.new(@commit)
    xml  = <<-END_XML
<changeset>
  <title>rick committed changeset [5]</title>
  <body>add bar</body>
  <changes>#{CGI.escapeHTML(hook.commit_changes.to_yaml)}</changes>
  <revision>5</revision>
  <changed-at type="datetime">abc</changed-at>
</changeset>
END_XML

    hook.changeset_xml.should == xml
  end
end