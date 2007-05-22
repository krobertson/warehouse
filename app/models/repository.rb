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
  
  has_many :changesets, :order => 'revision desc'
  has_many :changes, :through => :changesets, :order => 'changesets.revision desc'
  has_many :memberships, :conditions => ['active = ?', true]
  has_many :members, :through => :memberships, :source => :user, :select => 'users.*, memberships.login, memberships.id as membership_id, memberships.admin as membership_admin'
  has_many :all_memberships, :class_name => 'Membership', :foreign_key => 'repository_id', :dependent => :delete_all
  
  has_many :permissions, :conditions => ['active = ?', true]
  has_many :all_permissions, :class_name => 'Permission', :foreign_key => 'repository_id', :dependent => :delete_all
  
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'revision desc'
  before_destroy :clear_changesets
  
  def path=(value)
    write_attribute :path, value.to_s.gsub(/^\/|\/$/, '')
  end
  
  def latest_revision
    @latest_revision ||= backend.youngest_rev
  end

  def node(path, rev = nil)
    Node.new(self, path, rev)
  end

  def invite(user, options = {})
    user.identity_url = TokenGenerator.generate_simple
    user.token        = TokenGenerator.generate_random(user.identity_url)
    return nil unless user.save
    m = all_memberships.find_or_initialize_by_user_id(user.id)
    m.user_id    = user.id
    m.active     = true
    m.attributes = options
    m.save
  end
  
  def grant(user, options = {})
    p = all_permissions.find_or_initialize_by_user_id(user.id)
    p.user_id    = user.id
    p.active     = true
    p.attributes = options
    p.save
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
  
  protected
    def clear_changesets
      Change.delete_all ['changeset_id in (select id from changesets where repository_id = ?)', id]
      Changeset.delete_all ['repository_id = ?', id]
    end
end
