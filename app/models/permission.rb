class Permission < ActiveRecord::Base
  @@join_fields = 'permissions.login, permissions.id as permission_id, permissions.admin as permission_admin, permissions.changesets_count as permission_changesets_count, permissions.last_changed_at'
  cattr_reader :join_fields

  belongs_to :repository
  belongs_to :user
  before_create { |r| r.active = true }
  validates_presence_of :repository_id
  attr_accessible :login, :admin, :path, :full_access
  validate :presence_of_login_for_user
  validate :uniqueness_of_user_paths

  def login
    l = read_attribute :login
    l.blank? ? '*' : l
  end
  
  def formatted_path
    "/#{path}"
  end

  def path=(value)
    write_attribute :path, value.to_s.gsub(/^\/|\/$/, '')
  end

  def paths
    path.to_s.split '/'
  end

  def self.grant(repository, options = {}, &block)
    options = options.dup
    if paths = options.delete(:paths)
      permissions = paths.collect { |(index, p)| grant(repository, options.merge(p), &block) }
      first = permissions.first # return first failed permission if no permissions saved properly
      return permissions.reject(&:new_record?).first || first
    end
    m = repository.all_permissions.build
    m.active     = true
    m.attributes = options
    block.call(m) if block
    m.save
    m
  end
  
  def self.set(repository, user, options = {})
    return if options.blank?
    options     = options.dup
    permissions = repository.permissions.find_all_by_user_id(user ? user.id : nil)
    transaction do
      update_all ['login = ?, admin = ?', options[:login], options[:admin]], ['id IN (?)', permissions.collect(&:id)]
      unless options[:paths].blank?
        options[:paths].delete_if do |(index, path_options)|
          if path_options[:id]
            update_all ['path = ?, full_access = ?', path_options[:path], path_options[:full_access]], ['id = ?', path_options[:id]]
          end
        end
      end
      unless options[:paths].blank?
        user ? repository.invite(user, options) : repository.grant(options)
      end
    end
  end
  
  protected
    def uniqueness_of_user_paths
      path_query = path.blank? ? "(path is null or path = ?)" : 'path = ?'
      user_query = user_id.blank? ? "(user_id is null or user_id = ?)" : 'user_id = ?'
      num = self.class.count(:all, :conditions => ["repository_id = ? and #{user_query} and #{path_query}", repository_id, user_id.to_i, path.to_s])
      errors.add_to_base("Can only have one permission rule for the given user and path.") if num > (new_record? ? 0 : 1)
    end
    
    def presence_of_login_for_user
      if user_id
        errors.add(:login, "is required for users") if read_attribute(:login).blank?
      else
        errors.add(:login, "is not allowed for anonymous users") unless read_attribute(:login).blank?
      end
    end
end
