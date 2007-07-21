require File.dirname(__FILE__) + '/../test_helper'
Warehouse::Command.configure(ActiveRecord::Base.configurations['test'].symbolize_keys)

context "Command Change" do
  setup do
    @backend = stub(:fs => stub) 
    @command = Warehouse::Command.new
    @changes = []
    @command.stubs(:connection).returns(:changes => @changes)
    @repo = {:id => 1}
    @changeset = {:id => 7, :revision => 5, :repository_id => @repo[:id], :author => 'rick', :message => 'brb going to moon', :changed_at => (Time.now - 300).utc}
    @user = {:id => 6, :login => 'justin'}
    @command.stubs(:backend_for).with(@repo).returns(@backend)
  end

  specify "should sync revisions" do
    Time.expects(:now).returns(@changeset[:changed_at].localtime)
    @connection = {:users => stub(:where => [@user.merge(:login => @changeset[:author])])}
    @connection.expects(:transaction).yields
    @command.stubs(:connection).returns(@connection)
    @command.expects(:paginated_revisions).with(@repo, 1).returns([@changeset[:revision]])
    @command.expects(:create_changeset).with(@repo, @changeset[:revision]).returns(@changeset)
    @command.expects(:update_user_activity).with(@repo, {:id => @user[:id], :login => @changeset[:author]}, @changeset[:changed_at])
    @command.send(:sync_revisions_for, @repo, 1)
  end

  specify "should skip syncing if there are no revisions to sync" do
    @command.connection.stubs(:transaction).returns { raise("This shouldn't happen") }
    @command.expects(:paginated_revisions).with(@repo, 23).returns([])
    @command.sync_revisions_for(@repo, 23)
  end

  specify "should paginate revisions" do
    @command.expects(:recorded_revision_for).with(@repo).returns 75
    @command.expects(:latest_revision_for).with(@repo).returns 100
    @command.send(:paginated_revisions, @repo, 5).should == (75..79).to_a
  end
  
  specify "should list all revisions" do
    @command.expects(:recorded_revision_for).with(@repo).returns 75
    @command.expects(:latest_revision_for).with(@repo).returns 100
    @command.send(:paginated_revisions, @repo, 0).should == (75..100).to_a
  end

  specify "should get recorded revision" do
    @changesets_where = stub
    @changesets_where.expects(:reverse_order).with(:changed_at).returns(stub(:first => {:revision => 1}))
    @changesets = stub
    @changesets.expects(:where).with(:repository_id => @repo[:id]).returns(@changesets_where)
    @command.expects(:connection).returns(:changesets => @changesets)
    @command.send(:recorded_revision_for, @repo).should == 2
  end

  specify "should get initial revision" do
    @changesets_where = stub
    @changesets_where.expects(:reverse_order).with(:changed_at).returns(stub(:first => nil))
    @changesets = stub
    @changesets.expects(:where).with(:repository_id => @repo[:id]).returns(@changesets_where)
    @command.expects(:connection).returns(:changesets => @changesets)
    @command.send(:recorded_revision_for, @repo).should == 1
  end

  specify "should get latest revision" do
    @backend.expects(:youngest_rev).returns(75)
    @command.send(:latest_revision_for, @repo).should == 75
  end
  
  specify "should update user activity" do
    @changesets_where = stub
    @changesets_where.expects(:count).with(:id).returns 15
    @changesets = stub
    @changesets.expects(:where).with(:repository_id => @repo[:id]).returns(@changesets_where)
    
    @permissions_where = stub
    @permissions_where.expects(:update).with(:author => @user[:login], :last_changed_at => @changeset[:changed_at], :changesets_count => 15).returns(77)
    @permissions = stub
    @permissions.expects(:where).with(:user_id => @user[:id], :repository_id => @repo[:id]).returns(@permissions_where)
    
    @command.stubs(:connection).returns(:permissions => @permissions, :changesets => @changesets)
    @command.send(:update_user_activity, @repo, @user, @changeset[:changed_at]).should == 77
  end
  
  specify "should create changeset from revision" do
    @changesets = stub
    @changesets.expects(:<<).returns(@changeset[:id])
    @command.stubs(:connection).returns(:changesets => @changesets)
    @command.expects(:backend_for).with(@repo).returns(@backend)
    @backend.fs.expects(:prop).with(Svn::Core::PROP_REVISION_AUTHOR, 5).returns(@changeset[:author])
    @backend.fs.expects(:prop).with(Svn::Core::PROP_REVISION_LOG,    5).returns(@changeset[:message])
    @backend.fs.expects(:prop).with(Svn::Core::PROP_REVISION_DATE,   5).returns(@changeset[:changed_at].localtime)
    @command.expects(:create_change_from_changeset).with(@backend, @changeset)
    
    @command.send(:create_changeset, @repo, @changeset[:revision]).should == @changeset
  end
  
  specify "should create change with Add/Delete/Modify" do
    %w(A D M MVP).each do |name|
      @changes.clear
      @command.send(:process_change_path_and_save, {:id => 1}, name, "/foo")
      @changes.should == [{:changeset_id => 1, :name => name, :path => "/foo"}]
    end
  end
  
  specify "should create change with MV or CP" do
    %w(MV CP).each do |name|
      @changes.clear
      @command.send(:process_change_path_and_save, {:id => 1}, name, [1,2,3])
      @changes.should == [{:changeset_id => 1, :name => name, :path => 1, :from_path => 2, :from_revision => 3}]
    end
  end
  
  specify "should process changeset changes" do
    @root           = stub
    @base_root      = stub
    @changed_editor = stub
    @backend.fs.stubs(:root).with(5).returns(@root)
    @backend.fs.stubs(:root).with(4).returns(@base_root)
    Svn::Delta::ChangedEditor.stubs(:new).with(@root, @base_root).returns(@changed_editor)
    @changed_editor.stubs(:added_dirs).returns(['/foo'])
    @changed_editor.stubs(:added_files).returns(['/foo/bar.txt'])
    @changed_editor.stubs(:updated_dirs).returns(['/foo'])
    @changed_editor.stubs(:updated_files).returns(['/foo/bar.txt'])
    @changed_editor.stubs(:deleted_dirs).returns(['/copied', '/deleted'])
    @changed_editor.stubs(:deleted_files).returns(['/copied/file', '/deleted/file'])
    @changed_editor.stubs(:copied_dirs).returns([%w(a /copied b), %w(a /original b)])
    @changed_editor.stubs(:copied_files).returns([%w(a /copied/file b), %w(a /original/file b)])
    
    @base_root.expects :dir_delta
    @command.expects(:process_change_path_and_save).with(@changeset, 'A',  '/foo')
    @command.expects(:process_change_path_and_save).with(@changeset, 'A',  '/foo/bar.txt')
    @command.expects(:process_change_path_and_save).with(@changeset, 'M',  '/foo')
    @command.expects(:process_change_path_and_save).with(@changeset, 'M',  '/foo/bar.txt')
    @command.expects(:process_change_path_and_save).with(@changeset, 'D',  '/deleted')
    @command.expects(:process_change_path_and_save).with(@changeset, 'D',  '/deleted/file')
    @command.expects(:process_change_path_and_save).with(@changeset, 'MV', %w(a /copied b))
    @command.expects(:process_change_path_and_save).with(@changeset, 'MV', %w(a /copied/file b))
    @command.expects(:process_change_path_and_save).with(@changeset, 'CP', %w(a /original b))
    @command.expects(:process_change_path_and_save).with(@changeset, 'CP', %w(a /original/file b))
    
    @command.send(:create_change_from_changeset, @backend, @changeset)
  end
end