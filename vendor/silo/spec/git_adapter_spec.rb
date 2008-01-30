require File.join(File.dirname(__FILE__), 'spec_helper')
require 'silo/adapters/git'

describe Silo::Adapters::Git do
  @@latest_git = '29af1297abfe503ceb21ee5c3d2ed43245016ada'
  before do
    unless File.exist?($adapter_options[:git][:path])
      pending "git repo not available, try unzipping git_repo.tar.gz"
    end
    @repo = Silo::Repository.new(:git, $adapter_options[:git])
  end

  it "sets adapter with type and options hash" do
    repo = Silo::Repository.new(:git, :foo => :bar)
    (class << repo ; self ; end).should include(Silo::Adapters::Git)
    repo.options[:foo].should == :bar
  end

  it "retrieves latest revision" do
    @repo.latest_revision.should == @@latest_git
  end
  
  it "splits path into branch" do
    node = @repo.node_at("/master/foo/bar")
    node.path.should      == 'master/foo/bar'
    node.paths.should     == %w(master foo bar)
    node.branch.should    == 'master'
    node.only_path.should == 'foo/bar'
  end
  
  it "checks if node exists" do
    @repo.node_at("master/foo").should be_exist
    @repo.node_at("master/foo/bar").should_not be_exist
  end
  
  it "checks if node is a directory?" do
    @repo.node_at("master/foo").should be_dir
    @repo.node_at("master/test.html").should_not be_dir
    @repo.node_at("master/foo/bar").should_not be_dir
  end
  
  it "checks if node is a file?" do
    @repo.node_at("master/test.html").should be_file
    @repo.node_at("master/foo/.placeholder").should be_file
    @repo.node_at("master/test.html2").should_not be_file
    @repo.node_at("master/foo").should_not be_file
  end
  
  it "retrieves blame information" do
    @repo.node_at("master/test.html").blame.should == {1 => ['7bc8b12ce61348934846c2d684bd17fb48a48c2b', 'rick'], 2 => ['7246fb99d35ed63058fc82d70e34f6f60a8f8b21', 'rick'], :username_length => 4}
  end
  
  it "checks diffable? status" do
    @repo.node_at("master/foo").should_not be_diffable
    @repo.node_at("master/test.html").should be_diffable
  end

  it "retrieves branch names" do
    children = @repo.child_node_names_for(@repo.node_at("/"))
    children.should include('master')
  end
  
  it "retrieves child node names" do
    children = @repo.child_node_names_for(@repo.node_at("master"))
    children.should include('foo')
    children.should include("config.yml")
    children.should include("test.html")
  end
  
  {:latest_revision => "7246fb99d35ed63058fc82d70e34f6f60a8f8b21", :author => 'rick', :changed_at => Time.utc(2008, 1, 28, 2, 39, 49, 0), :message => 'updated'}.each do |attr, value|
    it "retrieves ##{attr} for given path" do
      @repo.node_at('master/test.html').send(attr).should == value
    end
  end
  
  it "reads contents of node" do
    @repo.node_at("master/config.yml").content.should == IO.read(File.join(File.dirname(__FILE__), 'mock_repo', 'config.yml'))
  end
  
  it "reads contents of nodes by version" do
    node         = @repo.node_at('master/test.html')
    current_test = node.content
    old_test     = node.previous_node.content
    current_test.should_not == old_test
    current_test.should     match(/bar/)
    current_test.should_not match(/baz/)
  end
  
  it "gets unified diff" do
    diff = @repo.node_at("test.html", '7bc8b12ce61348934846c2d684bd17fb48a48c2b').unified_diff_with(@repo.node_at("test.html", '7246fb99d35ed63058fc82d70e34f6f60a8f8b21'))
    diff.should match(/-baz/)
    diff.should match(/\+bar/)
  end
  
  it "knows '7246fb99d35ed63058fc82d70e34f6f60a8f8b21' is a revision" do
    @repo.revision?('7246fb99d35ed63058fc82d70e34f6f60a8f8b21').should == '7246fb99d35ed63058fc82d70e34f6f60a8f8b21'
  end
  
  it "knows '6' is not revision" do
    @repo.revision?('6').should be_nil
  end
  
  it "knows 6 is not revision" do
    @repo.revision?(6).should be_nil
  end
  
  it "knows 'HEAD' is not a revision" do
    @repo.revision?('HEAD').should be_nil
  end
  
  it "tracks latest? status" do
    node = @repo.node_at("master/test.html", '7246fb99d35ed63058fc82d70e34f6f60a8f8b21')
    node.should be_latest
    node.previous_node.should_not be_latest
  end

  describe "changeset changes" do
    it "lists added files" do
      @node = @repo.node_at('', '3da5d57d9c050a52459e16addb558025ffef48a5')
      @node.added_files.should include('added/added.txt')
      @node = @repo.node_at('', '29af1297abfe503ceb21ee5c3d2ed43245016ada')
      @node.added_files.should include('added/moved.txt')
    end
    
    it "lists updated files" do
      @node = @repo.node_at('', 'a5b187d462f822e1a6d7b832348d5e67acb9d108')
      @node.updated_files.should include('added/added.txt')
    end
    
    #it "lists copied files" do
    #  @node = @repo.node_at('', '29af1297abfe503ceb21ee5c3d2ed43245016ada')
    #  @node.copied_files.should include(['copied/copied.txt', 'copied/added.txt', '29af1297abfe503ceb21ee5c3d2ed43245016ada'])
    #end
    
    it "lists deleted files" do
      @node = @repo.node_at('', '29af1297abfe503ceb21ee5c3d2ed43245016ada')
      @node.deleted_files.should include('added/added.txt')
    end
  end
end