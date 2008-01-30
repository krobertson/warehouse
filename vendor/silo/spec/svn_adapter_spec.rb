require File.join(File.dirname(__FILE__), 'spec_helper')
require 'silo/adapters/svn'

describe Silo::Adapters::Svn do
  @@latest_svn = 7
  before do
    @repo = Silo::Repository.new(:svn, $adapter_options[:svn])
  end

  it "sets adapter with type and options hash" do
    repo = Silo::Repository.new(:svn, :foo => :bar)
    (class << repo ; self ; end).should include(Silo::Adapters::Svn)
    repo.options[:foo].should == :bar
  end

  it "retrieves latest revision" do
    @repo.latest_revision.should == @@latest_svn
  end
  
  it "ensures revision is an integer" do
    @repo.node_at("foo", "5").revision.should == 5
  end

  it "checks if node exists" do
    @repo.node_at("foo").should be_exist
    @repo.node_at("foo/bar").should_not be_exist
  end
  
  it "checks if node is a directory?" do
    @repo.node_at("foo").should be_dir
    @repo.node_at("foo/bar").should_not be_dir
  end
  
  it "checks if node is a file?" do
    @repo.node_at("test.html", 2).should be_file
    @repo.node_at("test.html2", 2).should_not be_file
  end

  it "retrieves blame information" do
    @blame = @repo.node_at("config.yml").blame
    @blame[:username_length].should == 4
    1.upto(16) { |i| @blame[i].should == [1, 'rick'] }
  end
  
  it "checks diffable? status" do
    @repo.node_at("test.html", 2).should be_diffable
    @repo.node_at("foo").should_not be_diffable
  end
  
  it "retrieves child node names" do
    children = @repo.node_at("/", 2).child_node_names
    children.should include('foo')
    children.should include("config.yml")
    children.should include("test.html")
  end

  {:latest_revision => @@latest_svn, :author => 'rick', :changed_at => Time.utc(2008, 1, 3, 0, 46, 39, 151238), :message => 'booya'}.each do |attr, value|
    it "retrieves ##{attr} for given path" do
      @repo.node_at('test.html', 2).send(attr).should == value
    end
  end
  
  it "reads contents of node" do
    @repo.node_at("config.yml").content.should == IO.read(File.join(File.dirname(__FILE__), 'mock_repo', 'config.yml'))
  end
  
  it "reads contents of nodes by version" do
    current_test = @repo.node_at('test.html', 2).content
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
    @repo.node_at("test.html", @@latest_svn).should be_latest
  end
  
  describe "changeset changes" do
    it "lists added files" do
      @node = @repo.node_at('', 3)
      @node.added_files.should include('added/')
      @node.added_files.should include('added/added.txt')
    end
    
    it "lists updated files" do
      @node = @repo.node_at('', 2)
      @node.updated_files.should include('test.html')
    end

    it "lists copied directories" do
      @node = @repo.node_at('', 4)
      @node.copied_files.should include(['copied/', 'added/', 3])
    end
    
    it "lists copied files" do
      @node = @repo.node_at('', 5)
      @node.copied_files.should include(['copied/copied.txt', 'copied/added.txt', 4])
    end

    it "lists deleted directories" do
      @node = @repo.node_at('', 6)
      @node.deleted_files.should include('copied/')
    end
    
    it "lists deleted files" do
      @node = @repo.node_at('', 7)
      @node.deleted_files.should include('test.html')
    end
  end
end