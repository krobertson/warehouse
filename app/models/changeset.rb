class Changeset < ActiveRecord::Base
  belongs_to :repository
  validates_presence_of   :repository_id, :revision
  validates_uniqueness_of :revision, :scope => :repository_id
  attr_accessible :revision, :author, :message, :changed_at
end
