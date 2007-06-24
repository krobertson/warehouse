require File.dirname(__FILE__) + '/../test_helper'

context "Command Sanitizer" do
  include CommandSanitizer
  setup do
    @args = {['a', 'b'] => %w(first last)}
  end
  
  specify "should handle command without args" do
    sanitize_command("foo", @args).should == 'foo'
  end
  
  specify "should replace args in command" do
    sanitize_command("foo :first :last", @args).should == "foo a b"
  end
  
  specify "should ignore unknown args" do
    sanitize_command("foo:bar :baz", @args).should == "foo:bar"
  end
end