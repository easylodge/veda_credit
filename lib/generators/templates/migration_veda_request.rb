class CreateVedaRequest < ActiveRecord::Migration
  def self.up
    create_table :veda_requests do |t|
      t.text :xml
      t.text :access
      t.text :product
      t.text :entity
      t.text :enquiry
      t.text :struct

      t.timestamps
    end
  end
  
  def self.down
    drop_table :veda_requests
  end
end