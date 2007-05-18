require File.dirname(__FILE__) + '/../test_helper'

context "Repository" do
  specify "should require name" do
    r = Repository.new(:path => 'foo')
    r.permalink = 'foo'
    r.should.not.be.valid
  end

  specify "should require path" do
    r = Repository.new(:name => 'foo')
    r.permalink = 'foo'
    r.should.not.be.valid
  end

  specify "should sanitize path" do
    r = Repository.new(:path => 'foo/')
    r.path.should == 'foo'
  end
  
  specify "should create permalink" do
    r = Repository.new(:name => 'Foo Bar', :path => 'foo/bar')
    assert_valid r
    r.permalink.should == 'foo-bar'
  end
end
