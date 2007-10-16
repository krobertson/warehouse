require File.join(File.dirname(__FILE__), '..', 'test_helper')

context "Commit" do
  before do
    @commit = Warehouse::Hooks::Commit.new(nil, 'foo/bar', 55)
  end
  
  it "should get repo path" do
    @commit.repo_path.should == 'foo/bar'
  end
  
  it "should get revision" do
    @commit.revision.should == 55
  end
  
  it "should get author" do
    @commit.expects(:svnlook).with(:author).returns('rick')
    @commit.author.should == 'rick'
    @commit.author.should == 'rick'
  end
  
  it "should get log" do
    @commit.expects(:svnlook).with(:log).returns('greetings universe')
    @commit.log.should == 'greetings universe'
    @commit.log.should == 'greetings universe'
  end
  
  it "should get changed" do
    @commit.expects(:svnlook).with(:changed).returns('M foo/bar/baz')
    @commit.changed.should == 'M foo/bar/baz'
    @commit.changed.should == 'M foo/bar/baz'
  end
  
  it "should get dirs_changed" do
    @commit.expects(:svnlook).with('dirs-changed').returns('foo')
    @commit.dirs_changed.should == 'foo'
    @commit.dirs_changed.should == 'foo'
  end
  
  it "should get changed_at" do
    @commit.expects(:svnlook).with(:date).returns('2007-10-14 11:59:43 UTC (Sun, 14 Oct 2007)')
    @commit.changed_at.should == Time.utc(2007, 10, 14, 11, 59, 43)
    @commit.changed_at.should == Time.utc(2007, 10, 14, 11, 59, 43)
  end
end