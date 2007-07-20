require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Command htpasswd" do
  @@htpasswd = File.join(RAILS_ROOT, 'tmp', 'warehouse', 'htpasswd')
  
  setup do
    @command = Warehouse::Command.new
    FileUtils.mkdir_p File.dirname(@@htpasswd)
    FileUtils.rm_rf @@htpasswd
  end
  
  specify "should build htpasswd from users" do
    @command.write_users_to_htpasswd [{:login => 'rick', :crypted_password => 'secret'}], @@htpasswd
    File.exist?(@@htpasswd).should == true
    IO.read(@@htpasswd).strip.should == "rick:secret"
  end
  
  specify "should build htpasswd from repo users" do
    @command.expects(:users_from_repo).with(:id => 1).returns([{:login => 'rick', :crypted_password => 'secret'}, {:login => 'justin', :crypted_password => 'secret'}])
    @command.write_repo_users_to_htpasswd({:id => 1}, @@htpasswd)
    File.exist?(@@htpasswd).should == true
    IO.read(@@htpasswd).strip.should == "justin:secret\nrick:secret"
  end
end