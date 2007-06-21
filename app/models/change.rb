class Change < ActiveRecord::Base
  validates_presence_of :changeset_id, :name
  belongs_to :changeset
  delegate :revision,     :to => :changeset
  delegate :unified_diff, :to => :node
  delegate :diffable?,    :to => :node

  
  def accessible_by?(user)
    return true  if (user && user.admin?) || changeset.repository.public?
    return false if user.nil?
    paths = user.permissions.paths_for(changeset.repository)
    paths == :all || paths.any? { |p| path == p || path =~ %r{^#{p}/} }
  end
  
  def node
    @node ||= changeset.repository.node(path, revision)
  end
  
  def backend
    changeset.repository.backend
  end
end
