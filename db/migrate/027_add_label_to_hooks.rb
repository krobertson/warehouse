class AddLabelToHooks < ActiveRecord::Migration
  def self.up
    add_column "hooks", "label", :string
  end

  def self.down
    remove_column "hooks", "label"
  end
end
