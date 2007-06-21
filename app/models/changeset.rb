class Changeset < ActiveRecord::Base
  belongs_to :repository
  has_many :changes
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
        conditions = conditions_for_paths(paths)
        with_scope :find => { :select => 'distinct changesets.*', :joins => 'inner join changes on changesets.id = changes.changeset_id', :conditions => conditions, :order => 'changesets.revision desc' }, &block
      end
    end
    
    def self.conditions_for_paths(paths)
      returning [[]] do |conditions|
        if paths.is_a? Hash
          paths.each do |repo, repo_paths|
            repository_conditions_for_paths repo, repo_paths, conditions
          end
        else
          repository_conditions_for_paths(nil, paths, conditions)
        end
        conditions[0] = conditions.first.join
      end
    end
    
    def self.repository_conditions_for_paths(repository, paths, conditions)
      if repository
        conditions.first << ' or ' unless conditions.first.empty?
        conditions.first << '(changesets.repository_id = ? and '
        conditions << repository 
      end
      
      unless paths == :all
        conditions.first << '(' \
          << Array.new(paths.size).fill('changes.path LIKE ?').join(" or ") \
          << " or changes.path IN (?)" \
          << ')'
        conditions.push(*paths.collect { |p| "#{p}/%" }).push(paths)
      end
      
      conditions.first << ')' if repository
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
