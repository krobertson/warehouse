require File.dirname(__FILE__) + '/../test_helper'

context "Change" do
  specify "should report admin user as accessible" do
    Change.new.accessible_by?(stub(:admin? => true)).should == true
  end
  
  specify "should report any user accessible for public repo" do
    ch = Change.new
    ch.stubs(:changeset).returns(stub(:repository => stub(:public? => true)))
    ch.accessible_by?(nil).should == true
    ch.accessible_by?(stub(:admin? => false)).should == true
  end
  
  specify "should report user with exact path as accessible" do
    changes(:one_moon).stubs(:changeset).returns(stub(:repository => stub(:public? => false)))
    changes(:one_moon).accessible_by?(stub(:admin? => false, :permissions => stub(:paths_for => ['moon']))).should == true
  end
  
  specify "should report user with base path as accessible" do
    changes(:one_moon_file).stubs(:changeset).returns(stub(:repository => stub(:public? => false)))
    changes(:one_moon_file).accessible_by?(stub(:admin? => false, :permissions => stub(:paths_for => ['moon']))).should == true
  end
  
  specify "should report user with root path as accessible" do
    changes(:one_moon_file).stubs(:changeset).returns(stub(:repository => stub(:public? => false)))
    changes(:one_moon_file).accessible_by?(stub(:admin? => false, :permissions => stub(:paths_for => :all))).should == true
  end
  
  specify "should not report user with bad path as accessible" do
    changes(:one_moon).stubs(:changeset).returns(stub(:repository => stub(:public? => false)))
    changes(:one_moon).accessible_by?(stub(:admin? => false, :permissions => stub(:paths_for => ['moo']))).should == false
  end
  
  specify "should not report user with no path as accessible" do
    changes(:one_moon).stubs(:changeset).returns(stub(:repository => stub(:public? => false)))
    changes(:one_moon).accessible_by?(stub(:admin? => false, :permissions => stub(:paths_for => []))).should == false
  end
end
