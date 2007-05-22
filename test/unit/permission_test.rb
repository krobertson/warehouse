require File.dirname(__FILE__) + '/../test_helper'

context "Permission" do
  specify "should grant user permission" do
    repositories(:sample).grant users(:justin), :path => ''
    p = repositories(:sample).permissions.find_by_user_id(users(:justin).id)
    p.path.should == ''
    p.should.be.active
    p.should.not.be.full_access
  end

  specify "should grant user full access" do
    repositories(:sample).grant users(:justin), :path => '/foo/', :full_access => true
    p = repositories(:sample).permissions.find_by_user_id(users(:justin).id)
    p.path.should == 'foo'
    p.should.be.active
    p.should.be.full_access
  end
end
