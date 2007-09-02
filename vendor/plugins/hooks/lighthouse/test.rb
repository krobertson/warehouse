require File.dirname(__FILE__) + '/../test_helper'
load_hook :lighthouse

context "Lighthouse" do
  setup do
    @commit = stub(:revision => 5, :changed => ['M foo', 'A foo/bar'].join("\n"), :author => 'rick', :log => 'add bar', :date => 'abc (def)')
    @hook   = Warehouse::Hooks::Lighthouse.new(@commit)
    @hook.init
  end
  
  specify "should keep option order" do
    Warehouse::Hooks::Lighthouse.option_order.collect { |order| order.split.first }.should == %w(prefix account project token users)
  end
  
  specify "should gather commit changes" do
    hook = Warehouse::Hooks::Lighthouse.new(@commit)
    hook.init
    hook.commit_changes.should == [%w(M foo), %w(A foo/bar)]
  end
  
  specify "should get use default token if no user token is available" do
    hook = Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test')
    hook.init
    hook.current_token.should == 'test'
  end
  
  specify "should get use user token if available" do
    hook = Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test', :users => 'rick foo')
    hook.init
    hook.current_token.should == 'foo'
  end
  
  specify "should construct url from options" do
    hook = Warehouse::Hooks::Lighthouse.new(@commit, :token => 'test', :project => '1')
    hook.init
    hook.changeset_url.should == "/projects/1/changesets.xml?_token=test"
  end
  
  specify "should construct changeset xml" do
    xml  = <<-END_XML
<changeset>
  <title>rick committed changeset [5]</title>
  <body>add bar</body>
  <changes>#{CGI.escapeHTML(@hook.commit_changes.to_yaml)}</changes>
  <revision>5</revision>
  <changed-at type="datetime">abc</changed-at>
</changeset>
END_XML

    @hook.changeset_xml.should == xml
  end
  
  specify "should require correct account format" do
    ['a b', '!adsf'].each do |value|
      @hook.account = value
      @hook.account.should.be.nil
    end
    
    %w(abc 123 a-b_c).each do |value|
      @hook.account = value
      @hook.account.should == value
    end
  end
  
  specify "should require correct token format" do
    ['a b', '!adsf', 'a-b_c'].each do |value|
      @hook.token = value
      @hook.token.should.be.nil
    end
    
    %w(abc 123).each do |value|
      @hook.token = value
      @hook.token.should == value
    end
  end
  
  specify "should require correct project format" do
    ['a b', '!adsf', 'a-b_c', 'abc'].each do |value|
      @hook.project = value
      @hook.project.should.be.nil
    end
    
    %w(123).each do |value|
      @hook.project = value
      @hook.project.should == value
    end
  end
  
  specify "should require correct users format" do
    ['!adsf', 'a-b_c', 'abc', '123', 'a b, c'].each do |value|
      @hook.users = value
      @hook.users.should.be.nil
    end
    
    ['a b', 'a b,   a b'].each do |value|
      @hook.users = value
      @hook.users.should == value
    end
  end
  
  specify "should parse users" do
    @hook.users = 'a b'
    @hook.init
    @hook.users.should == {'a' => 'b'}

    @hook.users = 'a b, c d'
    @hook.init
    @hook.users.should == {'a' => 'b', 'c' => 'd'}
  end
end