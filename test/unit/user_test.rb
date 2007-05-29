require File.dirname(__FILE__) + '/../test_helper'

context "User" do
  specify "should find users by login" do
    User.find_all_by_logins(repositories(:sample), %w(rick)).should == [users(:rick)]
  end
end
