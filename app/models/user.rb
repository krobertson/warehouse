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
        if proxy_owner.admin?
          memo.update repo.id => :all
        else
          (memo[repo.id] ||= []) << repo.permission_path
          memo
        end
      end
      return repo_paths if proxy_owner.admin?
      repo_paths.each do |repo_id, paths|
        repo_paths[repo_id] = :all if paths.include?(:all)
      end
      repo_paths
    end
  end
  
  attr_accessor :password
  validates_format_of       :email, :with => /(\A(\s*)\Z)|(\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z)/i, :allow_nil => true
  validates_confirmation_of :password, :allow_nil => true
  validates_uniqueness_of   :identity_url, :email, :allow_nil => true
  validate :presence_of_identity_url_or_email
  before_create :set_default_attributes
  before_save   :sanitize_email
  attr_accessible :identity_url, :avatar_data, :email, :login, :password, :password_confirmation
  belongs_to :avatar
  before_save :save_avatar_data

  def self.find_all_by_logins(logins)
    find :all, :conditions => ['login IN (?)', logins]
  end

  def self.authenticate(login, password)
    user = find_by_login(login)
    user && user.crypted_password == password.crypt(user.crypted_password[0,2]) ? user : nil
  end

  def name
    read_attribute(:login) || sanitized_email
  end

  def sanitized_email
    if !email.blank? && email =~ /^([^@]+)@(.*?)(\.co)?\.\w+$/
      "#{$1} (at #{$2})"
    end
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
  
  def reset_token!
    reset_token
    save
  end
  
  def identity_path
    identity_url.gsub(/^[^\/]+\/+/, '').chomp('/')
  end

  def identity_url=(value)
    write_attribute :identity_url, OpenIdAuthentication.normalize_url(value)
  end

  protected
    def set_default_attributes
      self.token = TokenGenerator.generate_random(TokenGenerator.generate_simple)
      self.admin = true if User.count.zero?
      true
    end

    def sanitize_email
      write_attribute :crypted_password, password.crypt(TokenGenerator.generate_simple(2)) unless password.blank?
      email.downcase! unless email.blank?
    end
    
    def presence_of_identity_url_or_email
      if identity_url.blank? && (email.blank? || login.blank?)
        errors.add_to_base "Requires at least an email and login"
      end
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
