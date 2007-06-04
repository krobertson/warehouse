class SetAnyUserTokens < ActiveRecord::Migration
  def self.up
    transaction do
      User.find(:all).each do |user|
        User.update_all ['token = ?', TokenGenerator.generate_random(TokenGenerator.generate_simple)], ['id = ?', user.id]
      end
    end
  end

  def self.down
  end
end
