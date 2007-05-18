require 'svn/repos'

# creating a sample local repo
#
#   cd db
#   svadmin create sample
#   mkdir foo
#   cd foo
#   svn import file:///Users/rick/p/xorn/trunk/db/sample/foo -m "initial"
#   rmdir foo
#   svn co file:///Users/rick/p/xorn/trunk/db/sample wc
class Repository < ActiveRecord::Base
  has_permalink :name
  validates_presence_of :name, :path, :permalink
  attr_accessible :name, :path
  
  has_many :changesets, :dependent => :delete_all
  has_one  :latest_changeset, :class_name => 'Changeset', :foreign_key => 'repository_id', :order => 'revision DESC'
  
  def path=(value)
    write_attribute(:path, value ? value.to_s.chomp('/') : nil)
  end
  
  def latest_revision
    @latest_revision ||= backend.youngest_rev
  end
  
  protected
    def backend
      @backend ||= Svn::Repos.open(path)
    end
end
