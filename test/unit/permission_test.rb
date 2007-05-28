require File.dirname(__FILE__) + '/../test_helper'

context "Permission" do
  specify "should accept user admin as repo member" do
    u = User.new
    u.stubs(:admin?).returns(true)
    repositories(:sample).member?(u).should == true
  end

  specify "should recognize anonymous member" do
    repositories(:sample).member?(nil).should == false
    repositories(:sample).member?(nil, 'public').should == true
    repositories(:sample).member?(nil, 'public/foo').should == true
  end

  specify "should recognize member" do
    User.update_all ['admin = ?', false]
    Permission.update_all ['admin = ?, path = ?', false, 'foo/bar']
    repositories(:sample).member?(users(:rick)).should == false
    repositories(:sample).member?(users(:rick), 'foo').should == false
    repositories(:sample).member?(users(:rick), 'foo/bar').should == true
    repositories(:sample).member?(users(:rick), 'foo/bar/baz').should == true
  end

  specify "should accept user admin as repo admin" do
    u = User.new
    u.stubs(:admin?).returns(true)
    repositories(:sample).admin?(u).should == true
  end
  
  specify "should recognize user admin" do
    repositories(:sample).admin?(users(:rick)).should == true
    repositories(:sample).admin?(users(:justin)).should == false
  end
  
  specify "should invite user" do
    u = User.new(:email => 'imagetic@wh.com')
    repositories(:sample).invite u, :login => 'imagetic'
    assert_valid u
    u.should.not.be.new_record
    p = repositories(:sample).permissions.find_by_user_id(u.id)
    p.login.should == 'imagetic'
    p.should.be.active
    p.should.not.be.admin
  end

  specify "should invite user as repo admin" do
    u = User.new(:email => 'imagetic@wh.com')
    repositories(:sample).invite u, :login => 'imagetic', :admin => true
    assert_valid u
    u.should.not.be.new_record
    p = repositories(:sample).permissions.find_by_user_id(u.id)
    p.login.should == 'imagetic'
    p.should.be.active
    p.should.be.admin
    u = repositories(:sample).members.find_by_id(u.id)
    u.should.be.permission_admin
  end

  specify "should invite existing user" do
    repositories(:sample).invite users(:justin), :login => 'justin'
    p = repositories(:sample).permissions.find_by_user_id(users(:justin).id)
    p.login.should == 'justin'
    p.should.be.active
    p.should.not.be.admin
    u = repositories(:sample).members.find_by_id(users(:justin).id)
    u.should.not.be.permission_admin
  end
  
  specify "should not duplicate permission rows" do
    assert_no_difference "Permission.count" do
      repositories(:sample).invite users(:rick), :login => 'rick', :paths => {'0' => {}, '1' => {:path => ''}}
    end
  end
  
  specify "should grant access to single path" do
    repositories(:sample).invite users(:justin), :login => 'justin', :paths => {'0' => {:path => 'foo'}}
    p = repositories(:sample).permissions.find_by_user_id(users(:justin).id)
    p.path.should == 'foo'
    p.should.not.be.full_access
  end
  
  specify "should grant access to single path" do
    repositories(:sample).invite users(:justin), :login => 'justin', :paths => {'0' => {:path => 'foo'}, '1' => {:path => 'bar', :full_access => true}}
    perms = repositories(:sample).permissions.find_all_by_user_id(users(:justin).id).sort_by(&:path)
    perms[0].path.should == 'bar'
    perms[0].should.be.full_access
    perms[1].path.should == 'foo'
    perms[1].should.not.be.full_access
  end
  
  specify "should update repository permissions" do
    assert_difference "Permission.count" do
      repositories(:sample).permissions.set(users(:rick), :login => 'technoweenie', :paths => {'0' => {:path => 'foo', :id => 1}, '1' => {:full_access => true}})
    end
    permissions = repositories(:sample).permissions.find_all_by_user_id(users(:rick).id).sort_by { |p| p.path.to_s }
    permissions[0].path.should.be.nil
    permissions[0].should.be.full_access
    permissions[1].should == permissions(:rick_sample)
    permissions[1].path.should == 'foo'
  end
  
  specify "should select permission properties" do
    u = repositories(:sample).members.find_by_id(users(:rick).id)
    u.login.should == 'rick'
    u.should.be.permission_admin
  end
  
  specify "should not set blank login for user permission" do
    p = repositories(:sample).invite users(:rick), :path => 'foo'
    p.errors.should.be.any
    p.errors.on(:login).should.not.be.nil
  end
  
  specify "should not allow login for anon permission" do
    p = repositories(:sample).grant :login => 'bobby', :path => 'foo'
    p.errors.should.be.any
    p.errors.on(:login).should.not.be.nil
  end
  
  specify "should find repository permissions" do
    users(:rick).permissions.for_repository(repositories(:sample)).should == [permissions(:rick_sample)]
  end
  
  specify "should find root repository permission paths" do
    users(:rick).permissions.paths_for(repositories(:sample)).should == :all
  end

  specify "should not find inactive repository permission paths" do
    Permission.update_all 'active = null'
    User.update_all 'admin = null'
    Repository.update_all 'public = null'
    users(:rick).permissions.paths_for(repositories(:sample)).should == []
  end

  specify "should find repository permission sub paths" do
    permissions(:rick_sample).update_attribute :path, 'bar'
    Permission.update_all ['active = ?', true]
    User.update_all 'admin = null'
    Repository.update_all 'public = null'
    users(:rick).permissions.paths_for(repositories(:sample)).sort.should == %w(bar foo)
  end
end
