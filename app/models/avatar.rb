class Avatar < ActiveRecord::Base
  has_attachment :storage => :file_system, :content_type => :image, :resize_to => '40x40'
  validates_as_attachment
  validates_length_of :filename, :maximum => 255
  before_destroy { |r| User.update_all 'avatar_id = NULL', ['avatar_id = ?', r.id] unless r.new_record? }
end
