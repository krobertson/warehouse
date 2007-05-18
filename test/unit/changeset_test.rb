require File.dirname(__FILE__) + '/../test_helper'

context "Changeset" do
  specify "should require repository_id" do
    ch = Changeset.new(:revision => 1)
    ch.should.not.be.valid
  end

  specify "should require repository-unique revision" do
    ch = Changeset.new(:revision => 1)
    ch.repository_id = 1
    ch.should.not.be.valid
    ch.repository_id = 5
    assert_valid ch
  end

  specify "should require revision" do
    ch = Changeset.new
    ch.repository_id = 5
    ch.should.not.be.valid
  end
end
