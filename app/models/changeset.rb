class Changeset < ActiveRecord::Base
  belongs_to :repository
  has_many :changes, :dependent => :delete_all
  validates_presence_of   :repository_id, :revision
  validates_uniqueness_of :revision, :scope => :repository_id
  attr_accessible :revision, :author, :message, :changed_at
  before_save :seed_svn_info
  after_save  :seed_svn_changes

  delegate :backend, :to => :repository
  expiring_attr_reader :user, :retrieve_user

  def self.paginate_by_path(path, options = {})
    with_paths([path]) { paginate(options) }
  end

  def self.find_all_by_path(path, options = {})
    with_paths([path]) { find :all, options }
  end

  def self.find_by_path(path, options = {})
    with_paths([path]) { find :first, options }
  end

  def self.paginate_by_paths(paths, options = {})
    with_paths(paths) { paginate(options) }
  end

  def self.find_all_by_paths(paths, options = {})
    with_paths(paths) { find :all, options }
  end

  def self.find_by_paths(paths, options = {})
    with_paths(paths) { find :first, options }
  end

  def to_param
    revision.to_s
  end
  
  def created_at
    read_attribute :changed_at
  end

  protected
    def self.with_paths(paths, &block)
      if paths == :all
        block.call
      else
        conditions = [Array.new(paths.size).fill('changes.path LIKE ?') * " or ", *paths.collect { |p| "#{p}/%" }]
        conditions.first << " or changes.path IN (?)"
        conditions       << paths
        with_scope :find => { :select => 'distinct changesets.*', :joins => 'inner join changes on changesets.id = changes.changeset_id', :conditions => conditions, :order => 'changesets.revision desc' }, &block
      end
    end

    def seed_svn_info
      self.author     = backend.fs.prop(Svn::Core::PROP_REVISION_AUTHOR, revision)
      self.message    = backend.fs.prop(Svn::Core::PROP_REVISION_LOG,    revision)
      self.changed_at = backend.fs.prop(Svn::Core::PROP_REVISION_DATE,   revision)
    end
    
    def seed_svn_changes
      Change.create_from_changeset(self)
    end

    def retrieve_user
      User.find_all_by_logins(repository, [author]).first
    end
end
