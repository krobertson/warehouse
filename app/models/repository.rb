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
  include PermissionMethods, CommandSanitizer
  has_permalink :name, :subdomain
  validates_presence_of :name, :path, :subdomain
  validates_inclusion_of :scm_type, :in => %w(svn git)
  attr_accessible :name, :path, :subdomain, :public, :full_url, :scm_type
  
  has_many :permissions, :conditions => ['active = ?', true] do
    def set(user_id, options = {})
      Permission.set(proxy_owner, user_id, options)
    end
  end
  has_many :members, :through => :permissions, :source => :user, :select => "users.*, #{Permission.join_fields}", :uniq => true
  has_many :all_permissions, :class_name => 'Permission', :foreign_key => 'repository_id', :dependent => :delete_all
  has_many :changesets, :order => 'changesets.changed_at desc'
  has_many :changes, :through => :changesets, :order => 'changesets.changed_at desc'
  has_many :bookmarks, :dependent => :destroy
  has_many :hooks, :dependent => :destroy
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'changed_at desc'
  before_destroy :clear_changesets
  after_create :create_repository
  after_destroy :remove_repository
  expiring_attr_reader :silo, :retrieve_silo

  def path=(value)
    write_attribute :path, value.to_s.chomp('/')
  end
  
  def full_url=(value)
    value << "/" unless value.last == "/" unless value.blank?
    write_attribute :full_url, value
  end

  def subdomain=(value)
    write_attribute :full_url, Warehouse.repository_url % [Warehouse.domain, value.downcase]
    write_attribute :path, File.join(Warehouse.repository_path, value.downcase)
    write_attribute :subdomain, value.downcase
  end
  
  def member?(user, path = nil)
    return true if public? || (user.is_a?(User) && user.admin?)
    conditions = [[]]
    if user
      conditions.first << "(user_id is null or user_id = ?)"
      conditions       << user.id
    end
    if path
      paths = path.to_s.split('/').inject([]) { |m, p| m << (m.last.nil? ? p : "#{m.last}/#{p}") }.unshift('')
      conditions.first << 'path in (?)'
      conditions       << paths
    end
    if conditions.size == 1
      conditions = nil
    else
      conditions[0] = conditions[0] * " and "
    end
    !permissions.count(:id, :conditions => conditions).zero?
  end
  
  def admin?(user)
    return nil unless user.is_a?(User)
    return true if user.admin?
    !permissions.count(:id, :conditions => ['user_id = ? and admin = ?', user.id, true]).zero?
  end
  
  def grant(options = {}, &block)
    Permission.grant(self, options, &block)
  end
  
  def set(user, options = {})
    Permission.set(self, user, options)
  end
  
  def domain
    [subdomain, Warehouse.domain] * '.'
  end

  def node(path, rev = nil)
    silo ? silo.node_at(path, rev) : nil
  end

  def revisions_to_sync
    return [] if silo.nil?
    # the module hasn't been extended yet.
    # calling silo extends it, but we need to call
    # the module's unbound method
    scm_type_mixin.instance_method(:revisions_to_sync).bind(self).call
  end
  
  def sync_progress
    return 0.0 if silo.nil?
    # the module hasn't been extended yet.
    # calling silo extends it, but we need to call
    # the module's unbound method
    scm_type_mixin.instance_method(:sync_progress).bind(self).call
  end
  
  def sync?
    silo && synced_revision && synced_revision != latest_revision.to_s
  end

  def latest_revision
    @latest_revision ||= silo && silo.latest_revision
  end

  def sync_revisions(num)
    stdout, stderr = execute_command "rake warehouse:sync REPO=#{id} NUM=#{num} RAILS_ENV=#{RAILS_ENV}"
    stderr = stderr.split("\n").delete_if { |e| e =~ /^rm -rf/ }.join("\n")
    [stdout, stderr]
  end

  def rebuild_permissions
    return if Warehouse.permission_command.blank?
    execute_command Warehouse.permission_command, self => %w(subdomain id)
  end

  def rebuild_htpasswd_for(user)
    return if Warehouse.password_command.blank?
    execute_command Warehouse.password_command, user => %w(id)
  end
  
  def self.rebuild_htpasswd_for(user)
    new.rebuild_htpasswd_for(user)
  end

  protected
    def create_repository
      silo.create_repository(id)
    end
    
    def remove_repository
      silo.remove_repository
    end

    # more efficient method of clearing out changesets and changes
    def clear_changesets
      Change.delete_all ['changeset_id in (select id from changesets where repository_id = ?)', id]
      Changeset.delete_all ['repository_id = ?', id]
    end

    def retrieve_silo
      scm_type_mixin
      path.blank? ? nil : Silo::Repository.new(scm_type, :path => path)
    rescue Svn::Error
      logger.warn $!.message
      nil
    end
    
    def scm_type_mixin
      if @scm_type_mixin.nil?
        @scm_type_mixin = self.class.const_get(scm_type.to_s.capitalize + "Methods")
        extend @scm_type_mixin
      end
      @scm_type_mixin
    end
end
