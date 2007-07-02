require File.dirname(__FILE__) + '/../test_helper'

context "Repository" do
  specify "should require name" do
    r = Repository.new(:path => 'foo')
    r.subdomain = 'foo'
    r.should.not.be.valid
  end

  specify "should require path" do
    r = Repository.new(:name => 'foo')
    r.subdomain = 'foo'
    r.should.not.be.valid
  end

  specify "should sanitize path" do
    r = Repository.new(:path => 'foo/')
    r.path.should == 'foo'
  end
  
  specify "should create subdomain" do
    r = Repository.new(:name => 'Foo Bar', :path => 'foo/bar')
    assert_valid r
    r.subdomain.should == 'foo-bar'
  end
  
  specify "should get initial revisions to sync" do
    r = Repository.new
    r.expects(:backend).returns(true)
    r.expects(:latest_changeset).returns(nil)
    r.expects(:latest_revision).returns(5)
    r.revisions_to_sync.should == (1..5)
  end
  
  specify "should get new revisions to sync" do
    r = Repository.new
    r.expects(:backend).returns(true)
    r.expects(:latest_changeset).times(2).returns(stub(:revision => 3))
    r.expects(:latest_revision).returns(5)
    r.revisions_to_sync.should == (4..5)
  end
  
  specify "should want to sync with revisions to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(true)
    repo.stubs(:revisions_to_sync).returns(1..5)
    repo.should.be.sync
  end
  
  specify "should want to sync with 1 revision to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(true)
    repo.stubs(:revisions_to_sync).returns(1..1)
    repo.should.be.sync
  end
  
  specify "should want to sync with no revisions to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(true)
    repo.stubs(:revisions_to_sync).returns(6..5)
    repo.should.not.be.sync
  end
end