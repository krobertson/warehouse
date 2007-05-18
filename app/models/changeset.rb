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

  protected
    def seed_svn_info
      self.author     = backend.fs.prop(Svn::Core::PROP_REVISION_AUTHOR, revision)
      self.message    = backend.fs.prop(Svn::Core::PROP_REVISION_LOG,    revision)
      self.changed_at = backend.fs.prop(Svn::Core::PROP_REVISION_DATE,   revision)
    end
    
    def seed_svn_changes
      Change.create_from_changeset(self)
    end
end
