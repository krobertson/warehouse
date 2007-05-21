# creating a sample local repo
#
#   cd db
#   svadmin create sample
#   mkdir foo
#   cd foo
#   svn import file:///Users/rick/p/xorn/trunk/db/sample/foo -m "initial"
#   rmdir foo
#   svn co file:///Users/rick/p/xorn/trunk/db/sample wc
class Repository < ActiveRecord::Base
  has_permalink :name, :subdomain
  validates_presence_of :name, :path, :subdomain
  attr_accessible :name, :path, :subdomain
  
  has_many :changesets, :order => 'revision desc', :dependent => :delete_all
  has_many :changes, :through => :changesets, :order => 'changesets.revision desc', :dependent => :delete_all
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'revision desc'
  
  def path=(value)
    write_attribute(:path, value ? value.to_s.chomp('/') : nil)
  end
  
  def latest_revision
    @latest_revision ||= backend.youngest_rev
  end

  def node(path, rev = nil)
    Node.new(self, path, rev)
  end

  def revisions_to_sync(refresh = false)
    unless refresh || @revisions_to_sync
      @revisions_to_sync = (latest_changeset ? latest_changeset.revision + 1 : 1)..latest_revision
    end
    @revisions_to_sync
  end
  
  def sync_revisions
    revisions_to_sync.collect do |rev|
      puts "##{rev}"
      changesets.create(:revision => rev)
    end
  end
  
  def sync_all_revisions!
    Changeset.delete_all
    Change.delete_all
    @revisions_to_sync = nil
    sync_revisions
  end

  def backend
    @backend ||= Svn::Repos.open(path)
  end
end
