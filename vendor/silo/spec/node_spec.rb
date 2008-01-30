require File.join(File.dirname(__FILE__), 'spec_helper')
load_adapter!

describe Silo::Node do
  @@sample_diff = "--- test.html (revision 2)
+++ test.html	(revision 1)

@@ -1,4 +1,3 @@
 foo
-bar!
-baz
+bar
"

  before do
    @repo = Silo::Repository.new($adapter_type, $adapter_options[$adapter_type])
    @node = @repo.node_at '/foo'
  end
  
  it "retrieves previous_node" do
    @node = @repo.node_at '/foo', 5
    @node.previous_node.path.should == @node.path
    @node.previous_node.revision.should == @node.revision - 1
  end
  
  it "is not diffable if !text?" do
    @node.should_receive(:text?).and_return(false)
    @node.should_not be_diffable
  end
  
  it "is not diffable if !previous_node.text?" do
    @node.should_receive(:text?).and_return(true)
    @node.previous_node.should_receive(:text?).and_return(false)
    @node.should_not be_diffable
  end
  
  it "is diffable if text? && previous_node.text?" do
    @node.should_receive(:text?).and_return(true)
    @node.previous_node.should_receive(:text?).and_return(true)
    @node.should be_diffable
  end
  
  it "strips beginning and ending '/' from paths" do
    @repo.node_at("/").path.should == ''
    @repo.node_at("/foo/").path.should == 'foo'
  end
  
  it "creates name for file node" do
    @node.stub!(:dir?).and_return(false)
    @node.name.should == 'foo'
  end
  
  it "creates name for directory node" do
    @node.stub!(:dir?).and_return(true)
    @node.name.should == 'foo/'
  end
  
  it "creates paths for node" do
    @repo.node_at("/foo/bar").paths.should == %w(foo bar)
  end
  
  %w(png jpg jpeg gif).each do |type|
    it "knows if 'image/#{type}' is an image" do
      @node.stub!(:dir?).and_return(false)
      @node.stub!(:mime_type).and_return("image/#{type}")
      @node.should be_image
    end
  end
  
  %w(txt html).each do |type|
    it "knows if '#{type}' is a text file" do
      @node.stub!(:file?).and_return(true)
      @node.stub!(:mime_type).and_return(type)
      @node.should be_text
    end
  end
  
  it "sorts nodes of the same type by the name" do
    [stubbed_node('b', true), stubbed_node('a', true)].sort.first.name.should == 'a/'
    [stubbed_node('b', false), stubbed_node('a', false)].sort.first.name.should == 'a'
  end
  
  it "sorts directories before files" do
    [stubbed_node('a', false), stubbed_node('b', true)].sort.first.name.should == 'b/'
  end

  it "checks if node exists" do
    @repo.node_at("foo").exists?.should     == true
    @repo.node_at("foo/bar").exists?.should == false
  end
  
  it "checks if node is a directory?" do
    @repo.node_at("foo").exists?.should     == true
    @repo.node_at("foo/bar").exists?.should == false
  end

  it "retrieves blame information" do
    @repo.node_at("test.html").blame.should == {1 => [1, 'rick'], 2 => [2, 'rick'], :username_length => 4}
  end
  
  it "retrieves child node names" do
    children = @repo.node_at("/").child_node_names
    children.should include('foo')
    children.should include("config.yml")
    children.should include("test.html")
  end

  it "retrieves child node objects" do
    @repo.node_at("/").child_nodes.should == [@repo.node_at("foo"), @repo.node_at("config.yml"), @repo.node_at("test.html")]
  end
  
  {:revision => 5, :author => 'rick', :changed_at => Time.utc(2008, 1, 2, 22, 35, 55), :message => 'booya'}.each do |attr, value|
    it "retrieves ##{attr} for given path" do
      @repo.node_at('test.html').send(attr).should == value
    end
  end

  it "generates unified diff for nodes" do
    @repo.should_receive(:unified_diff_for).with(5, 1, 'test.html').and_return(@@sample_diff)
    @repo.node_at('test.html').unified_diff_with(1).should == @@sample_diff
  end

  it "generates unified diff for nodes" do
    @repo.should_receive(:unified_diff_for).with(5, 1, 'test.html').and_return(@@sample_diff)
    @repo.node_at('test.html').unified_diff_with(@repo.node_at('test.html', 1)).should == @@sample_diff
  end

  it "generates unified diff for node against previous version" do
    @repo.should_receive(:unified_diff_for).with(5, 4, 'test.html').and_return(@@sample_diff)
    @repo.node_at('test.html').unified_diff.should == @@sample_diff
  end

  it "reads contents of node" do
    @repo.node_at("config.yml").content.should == IO.read(File.join(File.dirname(__FILE__), 'mock_repo', 'config.yml'))
  end

  def stubbed_node(path, dir)
    node = @repo.node_at path
    node.stub!(:dir?).and_return(dir)
    node
  end
end