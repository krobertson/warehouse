require File.join(File.dirname(__FILE__), 'abstract_unit')

class ActiveRecordContextTest < Test::Unit::TestCase
  def setup
    Post.destroy_all
    @posts = []
    @topic = Topic.create! :title => 'test'
    @posts << NormalPost.create!(:body => 'normal body', :topic => @topic)
    @posts << PolymorphPost.create!(:body => 'polymorph body', :topic => @topic)
    assert_nil Post.context_cache
  end

  def test_should_initialize_context_cache_hash
    Post.with_context do
      assert_kind_of Hash, Post.context_cache
      assert_equal 0, Post.context_cache.size
    end
    assert_nil Post.context_cache
  end

  def test_should_store_records_in_cache
    Post.with_context do
      records = Post.find(:all)
      assert_equal records.size, Post.context_cache[Post].size
      assert_equal @posts[0], Post.find_in_context(1)
      assert_equal @posts[1], Post.find_in_context(2)
    end
  end
  
  def test_should_find_records_in_context
    Post.with_context do
      records = Post.find(:all)
      Post.destroy_all
      assert_equal @posts[0], Post.find(1)
      assert_equal @posts[1], Post.find(2)
    end
    
    assert_raise ActiveRecord::RecordNotFound do
      Post.find 1
    end
  end
  
  def test_should_find_belongs_to_record
    Post.with_context do
      Topic.find :all ; Topic.delete_all
      assert_equal @topic, @posts[0].topic(true)
    end
    
    assert_equal @topic, @posts[0].topic
    assert_nil @posts[0].topic(true)
  end
  
  def test_should_find_belongs_to_polymorphic_record
    Post.with_context do
      Topic.find :all ; Topic.delete_all
      assert_equal @topic, @posts[1].topic(true)
    end
    
    assert_equal @topic, @posts[1].topic
    assert_nil @posts[1].topic(true)
  end
end
