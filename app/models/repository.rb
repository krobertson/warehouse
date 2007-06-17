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
  
  has_many :permissions, :conditions => ['active = ?', true] do
    def set(user_id, options = {})
      Permission.set(proxy_owner, user_id, options)
    end
  end
  has_many :members, :through => :permissions, :source => :user, :select => 'users.*, permissions.login, permissions.id as permission_id, permissions.admin as permission_admin'
  has_many :all_permissions, :class_name => 'Permission', :foreign_key => 'repository_id', :dependent => :delete_all
  has_many :changesets
  has_many :changes, :through => :changesets, :order => 'changesets.revision desc'
  has_many :bookmarks
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'revision desc'
  before_destroy :clear_changesets

  def path=(value)
    write_attribute :path, value.to_s.gsub(/^\/|\/$/, '')
  end

  def latest_revision
    @latest_revision ||= backend.youngest_rev
  end

  def member?(user, path = nil)
    return true if public? || (user.is_a?(User) && user.admin?)
    paths = path.to_s.split('/').inject([]) { |m, p| m << (m.last.nil? ? p : "#{m.last}/#{p}") }
    paths = [''] if paths.empty?
    !permissions.count(:id, :conditions => ["(user_id is null or user_id = ?) and (path is null or path in (?))", user ? user.id : 0, paths]).zero?
  end
  
  def admin?(user)
    return nil unless user.is_a?(User)
    return true if user.admin?
    !permissions.count(:id, :conditions => ['user_id = ? and admin = ?', user.id, true]).zero?
  end

  def invite(user, options = {})
    user.identity_url = TokenGenerator.generate_simple
    return nil unless user.save
    grant options do |m|
      m.user_id = user.id 
    end
  end
  
  def grant(options = {}, &block)
    Permission.grant(self, options, &block)
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
    clear_changesets
    @revisions_to_sync = nil
    revisions_to_sync.collect do |rev|
      puts "##{rev}"
      changesets.create(:revision => rev)
    end
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
