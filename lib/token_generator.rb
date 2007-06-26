require 'digest/sha1'
module TokenGenerator
  @@chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
  @@char_size = @@chars.size
  extend self
  
  def generate_simple(size = 8)
    (1..size).collect { |a| @@chars[rand(@@char_size)] }.join
  end
  
  def generate_random(seed = generate_simple)
    Digest::SHA1.hexdigest( seed + Time.now.to_s.split.sort_by { rand }.join )
  end
end