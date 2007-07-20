require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Command DB Access" do
  setup do
    @command = Warehouse::Command.new
  end

  specify "should find users for repository" do
    @command.send(:users_from_repo, :id => 1).to_a.collect { |row| row[:id] }.should == [1,2]
  end
  
  specify "should find repo by id" do
    @command.send(:find_repo, '1')[:id].should == 1
  end
  
  specify "should find repo by subdomain" do
    @command.send(:find_repo, 'sample')[:id].should == 1
  end
  
  specify "should find grouped permissions" do
    permissions = @command.send :grouped_permissions_for, [{:id => 1}]
    permissions.keys.should == %w(1)
    permissions['1'].collect { |p| p[:id] }.should == [1, 2, 6]
  end
  
  specify "should find grouped permission paths" do
    permissions = @command.send :grouped_permission_paths_for, [{:id => 1}]
    permissions.keys.should == %w(1)
    permissions['1'].keys.should == ['', 'public']
    permissions['1'][''].collect { |p| p[:id] }.should == [1, 6]
    permissions['1']['public'].collect { |p| p[:id] }.should == [2]
  end
  
  specify "should find indexed users from permissions" do
    users = @command.send :indexed_users_from, [1,2,6].collect! { |id| {:user_id => id} }
    users.keys.should == %w(1 2)
  end
  
  specify "should find repos from a user" do
    @command.repos_from_user(:id => 1).collect { |r| r[:id] }.should == [1,2]
  end
end