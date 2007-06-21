class User < ActiveRecord::Base
  include PermissionMethods  
  attr_accessor :avatar_data
  
  has_many :permissions, :conditions => ['active = ?', true] do
    def for_repository(repository)
      find_all_by_repository_id(repository.id)
    end
    
    def paths_for(repository)
      return :all if proxy_owner.admin? || repository.public?
      paths = for_repository(repository).collect! &:path
      root_paths, all_paths = paths.partition(&:blank?)
      root_paths.empty? ? all_paths : :all
    end
  end
  
  has_many :all_permissions, :class_name => 'Permission', :foreign_key => 'user_id', :dependent => :delete_all
  has_many :repositories, :through => :permissions, :select => "repositories.*, #{Permission.join_fields}", :order => 'repositories.name, permissions.path' do
    def paths
      repo_paths = proxy_owner.repositories.inject({}) do |memo, repo|
        (memo[repo.id] ||= []) << repo.permission_path
        memo
      end
      repo_paths.each do |repo_id, paths|
        repo_paths[repo_id] = :all if paths.include?(:all)
      end
      repo_paths
    end
  end
  
  validates_presence_of   :identity_url
  validates_format_of     :email, :with => /(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i, :allow_nil => true
  validates_uniqueness_of :identity_url
  validates_uniqueness_of :email, :allow_nil => true
  before_create :set_default_attributes
  before_save   :sanitize_email
  attr_accessible :name, :identity_url, :avatar_data, :email
  belongs_to :avatar
  before_save :save_avatar_data

  def self.find_all_by_logins(repository, logins)
    find(:all, :select => 'DISTINCT users.*, permissions.login',
      :conditions => login_conditions_for_repositories(repository.id => logins),
      :joins => 'inner join permissions on users.id = permissions.user_id')
  end
  
  def self.find_all_by_repositories(repositories)
    find(:all, :select => 'DISTINCT users.*, permissions.repository_id, permissions.login',
      :conditions => login_conditions_for_repositories(repositories),
      :joins => 'inner join permissions on users.id = permissions.user_id').index_by { |u| u.repository_id.to_i }
  end

  def name
    read_attribute(:name) || read_attribute(:login)
  end

  def email=(value)
    write_attribute :email, value.blank? ? value : value.downcase
  end

  def avatar?
    !avatar_id.nil?
  end

  def reset_token
    write_attribute :token, TokenGenerator.generate_random(TokenGenerator.generate_simple)
  end

  protected
    # takes a hash of repo_id => %w(logins)
    def self.login_conditions_for_repositories(repositories)
      returning [[]] do |conditions|
        repositories.each do |repo, logins|
          conditions.first << "(permissions.repository_id = ? AND permissions.login IN (?))"
          conditions << repo << logins
        end
        conditions[0] = conditions.first.join(" or ")
      end
    end

    def set_default_attributes
      self.token = TokenGenerator.generate_random(TokenGenerator.generate_simple)
      self.admin = true if User.count.zero?
      true
    end

    def sanitize_email
      email.downcase! unless email.blank?
    end

    def save_avatar_data
      return if @avatar_data.nil? || @avatar_data.size.zero?
      build_avatar if avatar.nil?
      avatar.uploaded_data = @avatar_data
      avatar.save!
      self.avatar_id   = avatar.id
      self.avatar_path = avatar.public_filename
    end
end
