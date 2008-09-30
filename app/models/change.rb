class Change < ActiveRecord::Base
  include PathAccessibility
  validates_presence_of :changeset_id, :name
  belongs_to :changeset
  delegate :revision,     :to => :changeset
  delegate :repository,   :to => :changeset
  delegate :unified_diff, :to => :node

  def node
    @node ||= changeset.repository.node(path, revision)
  end
  
  def diffable?
    node ? node.diffable? : false
  end
  
  def backend
    changeset.repository.backend
  end
  
  def modified?
    name =~ /m/i
  end
end
