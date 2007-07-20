require File.dirname(__FILE__) + '/../test_helper'

context "Command connections" do
  setup do
    @command = Warehouse::Command.new
  end

  specify "should build correct sequel connection string from activerecord config hash" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'mysql', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "mysql://rick:secret@myhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash without host value" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'mysql', :username => 'rick', :password => 'secret', :database => 'test').should == \
      "mysql://rick:secret@localhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash using postgresql" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'postgresql', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "postgres://rick:secret@myhost/test"
  end

  specify "should build correct sequel connection string from activerecord config hash using sqlite3" do
    Warehouse::Command.yaml_to_connection_string(:adapter => 'sqlite3', :username => 'rick', :password => 'secret', :host => 'myhost', :database => 'test').should == \
      "sqlite://test"
  end

  specify "should warn against sqlite2 usage" do
    assert_raises RuntimeError do
      Warehouse::Command.yaml_to_connection_string(:adapter => 'sqlite', :database => 'test')
    end
  end
end

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

context "Command svn access config" do
  @@config = File.join(RAILS_ROOT, 'tmp', 'warehouse', 'config')
  setup do
    @command = Warehouse::Command.new
    FileUtils.mkdir_p File.dirname(@@config)
    FileUtils.rm_rf @@config
  end
  
  specify "should build config file" do
    expected = <<-END
[repo1:/]
* = r
rick = rw

[repo2:/foo]
* = rw
rick = r
END
    repo1 = {:id => 1, :subdomain => 'repo1'}
    repo2 = {:id => 2, :subdomain => 'repo2'}
    
    @command.expects(:grouped_permission_paths_for).with([repo1, repo2]).returns(
      {'1' => {'' => [
          {:path => '', :full_access => 0},
          {:path => '', :full_access => 1, :user_id => 1 }
        ]},
      '2' => {'foo' => [
          {:path => 'foo', :full_access => 1},
          {:path => 'foo', :full_access => 0, :user_id => 1 }
        ]}
      }
    )
    
    @command.build_config_for [repo1, repo2], @@config
    File.exist?(@@config).should == true
    IO.read(@@config).strip.should == expected.strip
  end
end