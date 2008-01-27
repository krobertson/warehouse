require File.join(File.dirname(__FILE__), 'spec_helper')
require 'silo/adapters/svn'

describe Silo::Adapters::Svn do
  before do
    @repo = Silo::Repository.new(:svn, $adapter_options[:svn])
  end

  it "sets adapter with type and options hash" do
    repo = Silo::Repository.new(:svn, :foo => :bar)
    (class << repo ; self ; end).should include(Silo::Adapters::Svn)
    repo.options[:foo].should == :bar
  end

  it "retrieves latest revision" do
    @repo.latest_revision.should == 2
  end
  
  it "ensures revision is an integer" do
    @repo.node_at("foo", "5").revision.should == 5
  end

  it "checks if node exists" do
    @repo.exists?(@repo.node_at("foo")).should     == true
    @repo.exists?(@repo.node_at("foo/bar")).should == false
  end
  
  it "checks if node is a directory?" do
    @repo.exists?(@repo.node_at("foo")).should     == true
    @repo.exists?(@repo.node_at("foo/bar")).should == false
  end

  it "retrieves blame information" do
    @repo.blame_for(@repo.node_at("test.html")).should == {1 => [1, 'rick'], 2 => [2, 'rick'], :username_length => 4}
  end
  
  it "checks diffable? status" do
    @repo.node_at("test.html").should be_diffable
    @repo.node_at("foo").should_not be_diffable
  end
  
  it "retrieves child node names" do
    children = @repo.child_node_names_for(@repo.node_at("/"))
    children.should include('foo')
    children.should include("config.yml")
    children.should include("test.html")
  end

  {:latest_revision => 2, :author => 'rick', :changed_at => Time.utc(2008, 1, 3, 0, 46, 39, 151238), :message => 'booya'}.each do |attr, value|
    it "retrieves ##{attr} for given path" do
      @repo.send("#{attr}_for", @repo.node_at('test.html')).should == value
    end
  end
  
  it "reads contents of node" do
    @repo.node_at("config.yml").content.should == IO.read(File.join(File.dirname(__FILE__), 'mock_repo', 'config.yml'))
  end
  
  it "reads contents of nodes by version" do
    current_test = @repo.node_at('test.html').content
    old_test     = @repo.node_at('test.html', 1).content
    current_test.should_not == old_test
    current_test.should     match(/bar/)
    current_test.should_not match(/baz/)
  end
  
  it "gets unified diff" do
    diff = @repo.node_at("test.html", 1).unified_diff_with(@repo.node_at("test.html", 2))
    diff.should match(/-baz/)
    diff.should match(/\+bar/)
  end
  
  it "knows '6' is a revision" do
    @repo.revision?('6').should == 6
  end
  
  it "knows 6 is a revision" do
    @repo.revision?(6).should == 6
  end
  
  it "knows 'HEAD' is not a revision" do
    @repo.revision?('HEAD').should be_nil
  end
  
  it "tracks latest? status" do
    @repo.node_at("test.html", 1).should_not be_latest
    @repo.node_at("test.html", 2).should     be_latest
  end

  it "finds revision relative to 'HEAD'" do
    @node = @repo.node_at "test.html", 1
    @node.revision_relative_to("HEAD").should == 2
  end
  
  it "finds revision relative to 'PREV'" do
    @node = @repo.node_at "test.html", 2
    @node.revision_relative_to("PREV").should == 1
  end
  
  it "finds revision relative to 'NEXT'" do
    @node = @repo.node_at "test.html", 1
    @node.revision_relative_to("NEXT").should == 2
  end
  
  it "finds revision relative to 'NEXT' when latest" do
    @node = @repo.node_at "test.html", 2
    @node.revision_relative_to("NEXT").should be_nil
  end
end