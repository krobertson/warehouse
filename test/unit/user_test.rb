require File.dirname(__FILE__) + '/../test_helper'

context "User" do
  specify "should find users by login" do
    User.find_all_by_logins(repositories(:sample), %w(rick)).should == [users(:rick)]
    User.find_all_by_logins(repositories(:sample), %w(rick2)).should == [users(:rick)]
  end
  
  specify "should find user repositories" do
    users(:rick).repositories.should == [repositories(:example), repositories(:example), repositories(:sample)]
    users(:rick).repositories[0].path == 'foo'
    users(:rick).repositories[0].should.not.be.permission_admin
    users(:rick).repositories[1].path == 'public'
    users(:rick).repositories[1].should.not.be.permission_admin
    users(:rick).repositories[2].path == :all
    users(:rick).repositories[2].should.be.permission_admin
  end
end
