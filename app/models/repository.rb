require 'svn/repos'

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
  has_permalink :name
  validates_presence_of :name, :path, :permalink
  attr_accessible :name, :path
  
  has_many :changesets, :dependent => :delete_all
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'revision DESC'
  
  def path=(value)
    write_attribute(:path, value ? value.to_s.chomp('/') : nil)
  end
  
  def latest_revision
    @latest_revision ||= backend.youngest_rev
  end

  def revisions_to_sync(refresh = false)
    unless refresh || @revisions_to_sync
      @revisions_to_sync = (latest_changeset ? latest_changeset.revision + 1 : 1)..latest_revision
    end
    @revisions_to_sync
  end
  
  def sync_revisions
    revisions_to_sync.collect do |rev|
      changesets.create(:revision => rev)
    end
  end
  
  def sync_all_revisions!
    Changeset.delete_all
    @revisions_to_sync = nil
    sync_revisions
  end
  
  protected
    def backend
      @backend ||= Svn::Repos.open(path)
    end
end
