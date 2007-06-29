class Change < ActiveRecord::Base
  include PathAccessibility
  validates_presence_of :changeset_id, :name
  belongs_to :changeset
  delegate :revision,     :to => :changeset
  delegate :unified_diff, :to => :node
  delegate :diffable?,    :to => :node
  
  def node
    @node ||= changeset.repository.node(path, revision)
  end
  
  def backend
    changeset.repository.backend
  end
end
