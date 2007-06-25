class Permission < ActiveRecord::Base
  @@join_fields = 'permissions.path as permission_path, permissions.id as permission_id, permissions.admin as permission_admin, permissions.changesets_count as permission_changesets_count, permissions.last_changed_at'
  cattr_reader :join_fields

  belongs_to :repository
  belongs_to :user
  before_create { |r| r.active = true }
  validates_presence_of :repository_id
  attr_accessible :admin, :path, :full_access, :user, :user_id
  validate :uniqueness_of_user_paths
  
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
    m = repository.all_permissions.find_or_initialize_by_user_id_and_path(options[:user] ? options[:user].id : options[:user_id], options[:path].to_s)
    m.active     = true
    m.attributes = options
    block.call(m) if block
    m.save
    m
  end
  
  # updates existing paths, then passes on to #grant
  def self.set(repository, user, options = {})
    return if options.blank?
    options     = options.dup
    permissions = repository.permissions.find_all_by_user_id(user ? user.id : nil)
    transaction do
      update_all ['admin = ?', options[:admin]], ['id IN (?)', permissions.collect(&:id)] if permissions.any?
      unless options[:paths].blank?
        options[:paths].delete_if do |(index, path_options)|
          if path_options[:id]
            update_all ['path = ?, full_access = ?', path_options[:path], path_options[:full_access]], ['id = ?', path_options[:id]]
          end
        end
      end
      grant(repository, options.merge(:user => user)) unless options[:paths].blank?
    end
  end
  
  protected
    def uniqueness_of_user_paths
      path_query = path.blank? ? "(path is null or path = ?)" : 'path = ?'
      user_query = user_id.blank? ? "(user_id is null or user_id = ?)" : 'user_id = ?'
      num = self.class.count(:all, :conditions => ["repository_id = ? and #{user_query} and #{path_query}", repository_id, user_id.to_i, path.to_s])
      errors.add_to_base("Can only have one permission rule for the given user and path.") if num > (new_record? ? 0 : 1)
    end
end
