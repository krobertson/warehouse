require File.dirname(__FILE__) + '/../test_helper'

context "Membership" do
  specify "should invite user" do
    u = User.new(:email => 'imagetic@wh.com')
    u.invite_to repositories(:sample), :login => 'imagetic'
    assert_valid u
    u.should.not.be.new_record
    m = repositories(:sample).memberships.find_by_user_id(u.id)
    m.login.should == 'imagetic'
    m.should.be.active
    m.should.not.be.admin
  end

  specify "should invite user as repo admin" do
    u = User.new(:email => 'imagetic@wh.com')
    u.invite_to repositories(:sample), :login => 'imagetic', :admin => true
    assert_valid u
    u.should.not.be.new_record
    m = repositories(:sample).memberships.find_by_user_id(u.id)
    m.login.should == 'imagetic'
    m.should.be.active
    m.should.be.admin
    u = repositories(:sample).members.find_by_id(u.id)
    u.should.be.membership_admin
  end

  specify "should invite existing user" do
    users(:justin).invite_to repositories(:sample), :login => 'justin'
    m = repositories(:sample).memberships.find_by_user_id(users(:justin).id)
    m.login.should == 'justin'
    m.should.be.active
    m.should.not.be.admin
    u = repositories(:sample).members.find_by_id(users(:justin).id)
    u.should.not.be.membership_admin
  end
  
  specify "should select membership properties" do
    u = repositories(:sample).members.find_by_id(1)
    u.login.should == 'rick'
    u.should.be.membership_admin
  end
end
