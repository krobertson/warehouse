require 'svn/delta'
class Changeset < ActiveRecord::Base
  belongs_to :repository
  has_many :changes
  validates_presence_of   :repository_id, :revision
  validates_uniqueness_of :revision, :scope => :repository_id
  attr_accessible :revision, :author, :message, :changed_at
  before_save :seed_svn_info
  after_save  :seed_svn_changes

  delegate :backend, :to => :repository

  def self.find_all_by_path(path, options = {})
    with_path(path) { find :all, options }
  end

  def self.find_by_path(path, options = {})
    with_path(path) { find :first, options }
  end

  def to_param
    revision.to_s
  end

  protected
    def self.with_path(path, &block)
      with_scope :find => { :select => 'changesets.*', :joins => 'inner join changes on changesets.id = changes.changeset_id', :conditions => ['changes.path = ?', path], :order => 'changesets.revision desc' }, &block
    end

    def seed_svn_info
      self.author     = backend.fs.prop(Svn::Core::PROP_REVISION_AUTHOR, revision)
      self.message    = backend.fs.prop(Svn::Core::PROP_REVISION_LOG,    revision)
      self.changed_at = backend.fs.prop(Svn::Core::PROP_REVISION_DATE,   revision)
    end
    
    def seed_svn_changes
      Change.create_from_changeset(self)
    end
end
