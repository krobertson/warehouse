class Changeset < ActiveRecord::Base
  belongs_to :repository
  has_many :changes
  validates_presence_of   :repository_id, :revision
  validates_uniqueness_of :revision, :scope => :repository_id

  delegate :backend, :to => :repository
  expiring_attr_reader :user, :retrieve_user

  def self.search(query, options = {})
    with_search(query) { paginate(options) }
  end

  def self.paginate(options = {})
    options = {:count => 'distinct changesets.id'}.update(options)
    super
  end

  def self.paginate_by_path(path, options = {})
    with_paths([path]) { paginate(options) }
  end

  def self.find_all_by_path(path, options = {})
    with_paths([path]) { find :all, options }
  end

  def self.find_by_path(path, options = {})
    with_paths([path]) { find :first, options }
  end
  
  def self.search_by_paths(query, paths, options = {})
    with_search(query) { paginate_by_paths(paths, options = {}) }
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
  
  def self.find_by_date_for_path(date, path)
    with_paths([path]) { find :first, :conditions => ['changesets.changed_at >= ?', date] }
  end
  
  def self.find_latest_changeset(path = nil, revision = nil)
    latest_changeset = lambda { revision ? find_by_revision(revision) : find(:first, :order => 'changesets.changed_at desc') }
    path.blank? ? latest_changeset.call : with_paths([path], &latest_changeset)
  end

  def to_param
    revision.to_s
  end
  
  def created_at
    read_attribute :changed_at
  end

  protected
    # scope changesets query by change paths.  
    #
    # with_paths :all # show all changesets
    # with_paths nil  # no changesets
    # with_paths []   # no changesets
    # with_paths %w(foo bar) # changesets with changes starting w/ the given paths
    #
    # you can also scope for multiple repos by passing a hash of repo_id => paths
    # with_paths 1 => :all, 2 => [], 3 => %w(foo bar) # skips repo 2
    def self.with_paths(paths, &block)
      if paths == :all
        block.call
      else
        conditions = conditions_for_paths(paths)
        return [] if conditions.blank?
        with_scope :find => { :select => 'distinct changesets.*', :joins => 'inner join changes on changesets.id = changes.changeset_id', :conditions => conditions, :order => 'changesets.changed_at desc' }, &block
      end
    end
    
    def self.with_search(q, &block)
      if q.blank?
        block.call
      else
        with_scope :find => { :select => 'distinct changesets.*', :conditions => ['message LIKE ?', "%#{q}%"] }, &block
      end
    end
    
    # build conditions for the given paths.  Follow the rules from #with_paths above.
    def self.conditions_for_paths(paths)
      returning [[]] do |conditions|
        if paths.is_a? Hash
          paths.each do |repo, repo_paths|
            paths.delete(repo) if repo_paths.blank?
          end
          return nil if paths.empty?
          paths.each do |repo, repo_paths|
            repository_conditions_for_paths repo, repo_paths, conditions
          end
        else
          repository_conditions_for_paths(nil, paths, conditions)
        end
        conditions[0] = conditions.first.join
      end
    end
    
    # create change path conditions for a given repository
    # if repository is nil, assume it's being scoped elsewhere: @repository.changesets.find_by_paths...
    def self.repository_conditions_for_paths(repository, paths, conditions)
      return if paths.blank?
      if repository
        conditions.first << ' or ' unless conditions.first.empty?
        conditions.first << '(changesets.repository_id = ?'
        conditions.first << ' and ' unless paths == :all
        conditions << repository 
      end

      unless paths == :all
        conditions.first << '(' \
          << Array.new(paths.size).fill('changes.path LIKE ?').join(" or ") \
          << " or changes.path IN (?)" \
          << ')'
        conditions.push(*paths.collect { |p| "#{p}/%" })
        conditions.push(paths)
      end
      conditions.first << ')' if repository
    end

    def retrieve_user
      User.find_by_login(author)
    end
end
