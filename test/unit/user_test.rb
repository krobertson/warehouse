require File.dirname(__FILE__) + '/../test_helper'

context "User" do
  specify "should find users by login" do
    User.find_all_by_logins(%w(rick)).should == [users(:rick)]
    User.find_all_by_logins(%w(rick2)).should == []
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
    users(:rick).stubs(:admin?).returns(false)
    users(:rick).repositories.paths[repositories(:example).id].should == %w(home public)
  end
  
  specify "should show all paths for repository admin" do
    users(:rick).stubs(:admin?).returns(false)
    users(:rick).repositories.paths[repositories(:sample).id].should  == :all
  end
  
  specify "should show all paths for user with root access" do
    users(:justin).permissions.for_repository(repositories(:sample)).first.path.should == '/'
    users(:justin).permissions.paths_for(repositories(:sample)).should == :all
    users(:justin).repositories.paths[repositories(:sample).id].should == :all
  end
  
  specify "should show all paths for global admin" do
    Repository.any_instance.stubs(:permission_admin?).returns(false)
    users(:rick).repositories.paths[repositories(:sample).id].should  == :all
  end
  
  specify "should authenticate with httpbasic auth" do
    u = User.new :password => 'monkey'
    u.send :sanitize_email
    u.crypted_password.should.not.be.nil
    User.expects(:find_by_login).with('rick').returns(u)
    User.authenticate('rick', 'monkey').should.not.be.nil
  end
  
  specify "should require valid crypted pass" do
    u = User.new :password => 'monkey'
    u.send :sanitize_email
    u.crypted_password.should.not.be.nil
    User.expects(:find_by_login).with('rick').returns(u)
    User.authenticate('rick', 'chicken').should.be.nil
  end
  
  specify "should find administered repositories" do
    users(:rick).administered_repositories.should   == [repositories(:sample)]
    users(:justin).administered_repositories.should == []
  end
end

context "User with basic authentication" do
  before do
    @user       = User.new :password => 'foo', :login => 'bob'
    @old_scheme = Warehouse.authentication_scheme
    @old_realm  = Warehouse.authentication_realm
    Warehouse.authentication_scheme = 'basic'
    Warehouse.authentication_realm  = 'foo'
  end
  
  after do
    Warehouse.authentication_scheme = @old_scheme
    Warehouse.authentication_realm  = @old_realm
  end
  
  specify "should encrypt password" do
    TokenGenerator.expects(:generate_simple).with(2).returns('ab')
    @user.encrypt_password!
    @user.crypted_password.should == 'abQ9KY.KfrYrc'
  end
  
  specify "should decrypt password" do
    @user.encrypt_password!
    @user.password_matches?('foo').should == true
  end
end

context "User with plain authentication" do
  before do
    @user       = User.new :password => 'foo', :login => 'bob'
    @old_scheme = Warehouse.authentication_scheme
    @old_realm  = Warehouse.authentication_realm
    Warehouse.authentication_scheme = 'plain'
    Warehouse.authentication_realm  = 'foo'
  end
  
  after do
    Warehouse.authentication_scheme = @old_scheme
    Warehouse.authentication_realm  = @old_realm
  end
  
  specify "should encrypt password" do
    @user.encrypt_password!
    @user.crypted_password.should == 'foo'
  end
  
  specify "should decrypt password" do
    @user.encrypt_password!
    @user.password_matches?('foo').should == true
  end
end

context "User with md5 authentication" do
  before do
    @user       = User.new :password => 'foo', :login => 'bob'
    @old_scheme = Warehouse.authentication_scheme
    @old_realm  = Warehouse.authentication_realm
    Warehouse.authentication_scheme = 'md5'
    Warehouse.authentication_realm  = 'bar'
  end
  
  after do
    Warehouse.authentication_scheme = @old_scheme
    Warehouse.authentication_realm  = @old_realm
  end
  
  specify "should encrypt password" do
    @user.encrypt_password!
    @user.crypted_password.should == Digest::MD5::hexdigest("bob:bar:foo")
  end
  
  specify "should decrypt password" do
    @user.encrypt_password!
    @user.password_matches?('foo').should == true
  end
end
