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
  
  specify "should normalize full_url" do
    r = Repository.new :full_url => 'foo'
    r.full_url.should == 'foo/'
  end
  
  specify "should not normalize nil full_url" do
    r = Repository.new :full_url => nil
    r.full_url.should == nil
  end
  
  specify "should not normalize normalized full_url" do
    r = Repository.new :full_url => 'foo/'
    r.full_url.should == 'foo/'
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
    repo = Repository.new
    repo.expects(:backend).returns(stub(:youngest_rev => 5))
    repo.expects(:latest_changeset).times(4).returns(stub(:revision => 3))
    repo.expects(:latest_revision).times(2).returns(5)
    repo.revisions_to_sync.to_a.should == [4,5]
    repo.sync_progress.should == 60
  end
  
  specify "should want to sync with revisions to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(stub(:youngest_rev => 5))
    repo.stubs(:synced_revision).returns(1)
    repo.revisions_to_sync.to_a.should == [1,2,3,4,5]
    repo.should.be.sync
    repo.sync_progress.should == 0
  end
  
  specify "should want to sync with 1 revision to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(stub(:youngest_rev => 1))
    repo.stubs(:synced_revision).returns(1)
    repo.revisions_to_sync.to_a.should == [1]
    repo.should.be.sync
    repo.sync_progress.should == 0
  end
  
  specify "should not want to sync with no revisions to sync" do
    repo = Repository.new
    repo.stubs(:backend).returns(stub(:youngest_rev => 5))
    repo.stubs(:synced_revision).returns(6)
    repo.revisions_to_sync.to_a.should == []
    repo.should.not.be.sync
    repo.sync_progress.should == 100
  end
  
  specify "should ignore rm -rf stderr message in #sync_revisions" do
    repo = Repository.new
    repo.expects(:execute_command).returns([nil, 'rm -rf /data/warehouse/releases/20070704061415/tmp/cache'])
    repo.sync_revisions(5).should == [nil, '']
  end
end