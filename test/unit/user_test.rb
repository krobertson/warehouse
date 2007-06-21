require File.dirname(__FILE__) + '/../test_helper'

context "User" do
  specify "should find users by login" do
    User.find_all_by_logins(repositories(:sample), %w(rick)).should == [users(:rick)]
    User.find_all_by_logins(repositories(:sample), %w(rick2)).should == [users(:rick)]
  end
  
  specify "should find user repositories" do
    users(:rick).repositories.should == [repositories(:example), repositories(:example), repositories(:sample)]
    users(:rick).repositories[0].permission_path.should == 'home'
    users(:rick).repositories[0].should.not.be.permission_admin
    users(:rick).repositories[1].permission_path.should == 'public'
    users(:rick).repositories[1].should.not.be.permission_admin
    users(:rick).repositories[2].permission_path.should == :all
    users(:rick).repositories[2].should.be.permission_admin
  end
  
  specify "should find user repository paths" do
    paths = users(:rick).repositories.paths
    paths[repositories(:example).id].should == %w(home public)
    paths[repositories(:sample).id].should  == [:all]
  end
end
