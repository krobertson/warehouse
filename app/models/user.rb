class User < ActiveRecord::Base
  attr_accessor :avatar_data
  validates_presence_of :identity_url
  validates_uniqueness_of :identity_url
  before_save :set_admin_if_needed
  attr_accessible :name, :identity_url, :avatar_data
  belongs_to :avatar
  before_save :save_avatar_data

  def avatar?
    !avatar_id.nil?
  end

  protected
    def set_admin_if_needed
      self.admin = true if User.count.zero?
      true
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
