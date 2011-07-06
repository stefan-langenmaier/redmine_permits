class SetupPermit < ActiveRecord::Migration
  
  def self.up

    create_table "permits", :force => true do |t|
      t.column "tracker_id", :integer, :default => 0, :null => false
      t.column "role_id", :integer, :default => 0, :null => false
#      t.column "fieldtype", :string, :default => "builtin", :null => false
      t.column "fieldname", :string, :default => "", :null => false
      t.column "visible", :boolean, :default => true, :null => false
      t.column "writable", :boolean, :default => true, :null => false
    end
    
  end
  
  def self.down
    drop_table :permits
  end
  
end