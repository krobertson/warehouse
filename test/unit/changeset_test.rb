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
    repositories(:sample).changesets.find_by_path('moon').should == changesets(:two)
  end
  
  specify "should find all changesets with root path" do
    Changeset.find_all_by_paths(:all).size.should == 4
  end
  
  specify "should find all changesets for multiple repositories" do
    Changeset.find_all_by_paths(1 => :all, 2 => %w(foo)).size.should == 3
  end
  
  specify "should find changesets in root path" do
    Changeset.find_all_by_path('moon').size.should == 2
  end
  
  specify "should hide changesets outside of given paths" do
    Changeset.find_all_by_paths(%w(baz bar)).should.be.empty
  end
end