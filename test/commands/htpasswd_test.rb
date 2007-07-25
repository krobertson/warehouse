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
    IO.read(@@htpasswd).strip.should == "rick:secret\njustin:secret"
  end

  specify "should import users from htpasswd" do
    IO.expects(:read).with('htpasswd').returns("rick:secret\njustin:secret")
    User.any_instance.expects(:valid?).times(3).returns(false, true, true)
    User.any_instance.expects(:login=).with('rick')
    User.any_instance.expects(:login=).with('rick_2')
    User.any_instance.expects(:login=).with('justin')
    User.any_instance.expects(:email=).with('rick@activereload.net')
    User.any_instance.expects(:email=).with('justin@activereload.net')
    User.any_instance.expects(:save!).times(2)
    @command.import_users_from_htpasswd('htpasswd', 'activereload.net')
  end

  specify "should import users from htpasswd and grant repo access" do
    IO.expects(:read).with('htpasswd').returns("rick:secret")
    user = User.new(:login => 'rick')
    User.expects(:new).with(:login => 'rick').returns(user)
    user.expects(:valid?).returns(true)
    user.expects(:email=).with('rick@activereload.net')
    user.expects(:save!)
    repo = Repository.new
    repo.expects(:grant).with(:path => '/foo', :user => user, :full_access => true)
    @command.import_users_from_htpasswd('htpasswd', 'activereload.net', repo, '/foo', true)
  end
end