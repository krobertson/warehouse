require File.dirname(__FILE__) + '/../test_helper'

context "Change" do
  %w(MV CP).each do |name|
    specify "should process orig_path for #{name}" do
      ch = Change.new(:name => name, :orig_path => %w(foo bar 2))
      ch.changeset_id = 2
      ch.save.should.be true
      ch.path.should == 'foo'
      ch.from_path.should == 'bar'
      ch.from_revision.should == 2
    end
  end
  
  specify "should leave orig_path when not moving or copying" do
    ch = Change.new(:name => 'A', :path => 'foo')
    ch.changeset_id = 2
    ch.save.should.be true
    ch.path.should == 'foo'
    ch.from_path.should.be.nil
    ch.from_revision.should.be.nil
  end
end
