require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

context "Commit" do
  %w(author dirs_changed log changed).each do |attr|
    specify "#{attr} should expire" do
      commit = Warehouse::Hooks::Commit.new('', 1)
      commit.expects(:svnlook).returns(5)
      2.times { commit.send(attr).should == 5 }
    end
  end
  
  specify "should only run valid hooks" do
    ValidHook.any_instance.expects(:run)
    Warehouse::Hooks::Commit.run '', 1, [[ValidHook, {}], [InvalidHook, {}]]
  end
end

class ValidHook
  def valid?() true end
  def initialize(commit, options)
  end
end

class InvalidHook < ValidHook
  def valid?() false end
  def run() raise end
end