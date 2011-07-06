class AddStatus < ActiveRecord::Migration
  
  def self.up

    add_column :permits, :status_id, :integer
    
  end
  
  def self.down
    remove_column :permits, :status_id
  end
  
end