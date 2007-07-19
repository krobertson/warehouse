require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

context "Hooks" do
  specify "should define hook class with #run method" do
    begin
      Warehouse::Hooks.const_defined?(:HookSingleMethods).should == false
      
      Warehouse::Hooks.define :hook_single_methods do 
        'hi'
      end
      
      Warehouse::Hooks::HookSingleMethods.new(nil).run.should == 'hi'
      
      Warehouse::Hooks.const_defined?(:HookSingleMethods).should == true
    ensure
      Warehouse::Hooks.send(:remove_const, :HookSingleMethods) if Warehouse::Hooks.const_defined?(:HookSingleMethods)
    end
  end
  
  specify "should define hook class with multiple methods" do
    begin
      Warehouse::Hooks.const_defined?(:HookMultipleMethods).should == false
      
      Warehouse::Hooks.define :hook_multiple_methods do |hook|
        hook.receiver { 'bob' }
        hook.run      { "hi #{receiver}" }
      end
      
      Warehouse::Hooks::HookMultipleMethods.new(nil).run.should == 'hi bob'
      
      Warehouse::Hooks.const_defined?(:HookMultipleMethods).should == true
    ensure
      Warehouse::Hooks.send(:remove_const, :HookMultipleMethods) if Warehouse::Hooks.const_defined?(:HookMultipleMethods)
    end
  end
end

context "Base" do
  specify "should check validity of hook" do
    commit = stub(:dirs_changed => %w(foo/bar foo baz).join("\n"))
    Warehouse::Hooks::Base.new(commit).should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => '').should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => '^foo').should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => '/^baz/').should.be.valid
    Warehouse::Hooks::Base.new(commit, :prefix => '/^bar').should.not.be.valid
  end
end

context "Commit" do
  %w(author dirs_changed log changed).each do |attr|
    specify "#{attr} should expire" do
      commit = Warehouse::Hooks::Commit.new('', 1)
      commit.expects(:svnlook).returns(5)
      2.times { commit.send(attr).should == 5 }
    end
  end
  
  specify "should only run valid hooks" do
    ValidHook.any_instance.expects(:run!)
    Warehouse::Hooks::Commit.run '', 1, [[ValidHook, {}], [InvalidHook, {}]]
  end
end

Warehouse::Hooks.discovered.each do |hook|
  test_file = File.join($hooks_root, hook.plugin_name, 'test')
  require test_file if File.exist?(test_file + '.rb')
end

class ValidHook
  def valid?() true end
  def initialize(commit, options) end
  def run() end
end

class InvalidHook < ValidHook
  def valid?() false end
  def run!() raise end
end