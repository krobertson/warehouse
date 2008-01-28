require File.dirname(__FILE__) + '/../test_helper'
require 'changesets_helper'


context "ChangesetsHelper#find_revision_for(node, other) with SVN" do
  include ChangesetsHelper

  setup do
    @changeset = "CHANGESET"
    @repo = Silo::Repository.new(:svn, :path => 'foo')
    @repo.stubs(:changesets).returns([])
    @node = @repo.node_at("/foo", 5)
  end
  
  it "finds absolute node" do
    other = @repo.node_at("/foo", 6)
    find_revision_for(@node, other).should == other
  end
  
  it "finds absolute revision with string" do
    find_revision_for(@node, '6').should == 6
  end
  
  it "finds absolute revision with integer" do
    find_revision_for(@node, 6).should == 6
  end
  
  it "finds revision for date" do
    @repo.changesets.expects(:find_by_date_for_path).with(1.day.ago.to_date, @node.path).returns(stub(:revision => 75))
    find_revision_for(@node, 1.day.ago.to_date).should == 75
  end
  
  it "finds relative revision from 'HEAD'" do
    @repo.changesets.expects(:find).with(:first).returns(stub(:revision => 70))
    find_revision_for(@node, "HEAD").should == 70
  end
  
  it "finds relative revision from 'PREV'" do
    @repo.changesets.expects(:find_before).with(changeset_paths, @changeset).returns(stub(:revision => 70))
    find_revision_for(@node, "PREV").should == 70
  end
  
  it "finds relative revision from 'NEXT'" do
    @repo.changesets.expects(:find_after).with(changeset_paths, @changeset).returns(stub(:revision => 70))
    find_revision_for(@node, "NEXT").should == 70
  end
  
  it "raises Silo::Node::Error on invalid relative revision" do
    assert_raises Silo::Node::Error do
      find_revision_for(@node, "FOO")
    end
  end
  
  def current_repository
    @repo
  end
  
  def changeset_paths
    []
  end
end