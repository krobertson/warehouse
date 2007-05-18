require File.dirname(__FILE__) + '/../test_helper'

context "Changeset" do
  specify "should require repository_id" do
    ch = Changeset.new(:revision => 1)
    ch.should.not.be.valid
  end

  specify "should require repository-unique revision" do
    ch = Changeset.new(:revision => 1)
    ch.repository_id = 1
    ch.should.not.be.valid
    ch.repository_id = 5
    assert_valid ch
  end

  specify "should require revision" do
    ch = Changeset.new
    ch.repository_id = 5
    ch.should.not.be.valid
  end
  
  specify "should find latest changeset" do
    repositories(:sample).latest_changeset.should == changesets(:two)
  end
  
  specify "should find by path" do
    repositories(:sample).changesets.find_all_by_path('moon/file.txt').should == [changesets(:two), changesets(:one)]
    repositories(:sample).changesets.find_all_by_path('moon').should == [changesets(:one)]
    repositories(:sample).changesets.find_by_path('moon').should == changesets(:one)
  end
  
  specify "should seed svn info" do
    changed_at = 5.minutes.ago.utc
    fs_stub = stub
    fs_stub.expects(:prop).with(Svn::Core::PROP_REVISION_AUTHOR, 3).returns('rick')
    fs_stub.expects(:prop).with(Svn::Core::PROP_REVISION_LOG, 3).returns('hello')
    fs_stub.expects(:prop).with(Svn::Core::PROP_REVISION_DATE, 3).returns(changed_at)
    Changeset.any_instance.expects(:backend).times(3).returns(stub(:fs => fs_stub))
    Change.expects(:create_from_changeset).returns(true)
    
    ch = Changeset.new(:revision => 3)
    ch.repository_id = 1
    ch.save.should.be true
    ch.author.should == 'rick'
    ch.message.should == 'hello'
    ch.changed_at.should == changed_at
  end
end