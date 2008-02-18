class Change < ActiveRecord::Base
  def self.per_page() 15 end
  include PathAccessibility
  validates_presence_of :changeset_id, :name
  belongs_to :changeset
  delegate :revision,     :to => :changeset
  delegate :repository,   :to => :changeset
  delegate :unified_diff, :to => :node

  def node
    @node ||= changeset.repository.node(path, revision)
  end
  
  def silo
    changeset.repository.silo
  end
  
  def modified?
    name =~ /m/i
  end
end
