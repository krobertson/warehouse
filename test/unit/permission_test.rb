require File.dirname(__FILE__) + '/../test_helper'

context "Permission" do
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
      repositories(:sample).invite users(:rick), :login => 'rick', :paths => [{}, {:path => ''}]
    end
  end
  
  specify "should grant access to single path" do
    repositories(:sample).invite users(:justin), :login => 'justin', :paths => [{:path => 'foo'}]
    p = repositories(:sample).permissions.find_by_user_id(users(:justin).id)
    p.path.should == 'foo'
    p.should.not.be.full_access
  end
  
  specify "should grant access to single path" do
    repositories(:sample).invite users(:justin), :login => 'justin', :paths => [{:path => 'foo'}, {:path => 'bar', :full_access => true}]
    perms = repositories(:sample).permissions.find_all_by_user_id(users(:justin).id).sort_by(&:path)
    perms[0].path.should == 'bar'
    perms[0].should.be.full_access
    perms[1].path.should == 'foo'
    perms[1].should.not.be.full_access
  end
  
  specify "should update repository permissions" do
    assert_difference "Permission.count" do
      repositories(:sample).permissions.set(users(:rick), :login => 'technoweenie', :paths => [{:path => 'foo', :id => 1}, {:full_access => true}])
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
end
