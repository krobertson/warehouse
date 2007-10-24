require File.dirname(__FILE__) + '/../test_helper'

context "Node finding revision" do
  before do
    @repo = stub :latest_revision => 10, :changesets => []
    @node = Node.new @repo, 'foo', 5
  end
  
  it "should find Fixnum revision" do
    @node.find_revision(6, 'foo').should == 6
  end
  
  it "should find revision from string number" do
    @node.find_revision('6', 'foo').should == 6
  end
  
  it "should find revision for date" do
    d = Date.today
    @changeset = stub :revision => 4
    @repo.changesets.expects(:find_by_date_for_path).with(d, 'foo').returns(@changeset)
    @node.find_revision(d, 'foo').should == 4
  end
  
  it "should not find revision for unsupported type" do
    assert_raises Node::Error do
      @node.find_revision(@node, 'foo')
    end
  end
  
  it "should allow string revision" do
    @node.find_revision('PREV', 'foo').should == 'PREV'
  end
  
  {
    [1,  'HEAD'] => 10,
    [5,  'PREV'] => 4,
    [5,  'NEXT'] => 6,
    [10, 'NEXT'] => 10
  }.each do |args, expected|
    it "should parse string revision for #{args.last.inspect}" do
      @node.relative_revision_to(*args).should == expected
    end
  end
  
  it "should not check two string revisions" do
    assert_raises Node::Error do
      @node.check_revisions('a', 'b')
    end
  end
  
  it "should check revisions for valid integers" do
    @node.check_revisions(1, 2).should == [1,2]
  end
  
  it "should parse older revision string against newer revision" do
    @node.check_revisions("PREV", 5).should == [4,5]
  end
  
  it "should parse newer revision string against older revision" do
    @node.check_revisions(5, "NEXT").should == [5,6]
  end
  
  it "should raise if values aren't acceptable" do
    assert_raises Node::Error do
      @node.check_revisions 5, nil
    end
  end
end