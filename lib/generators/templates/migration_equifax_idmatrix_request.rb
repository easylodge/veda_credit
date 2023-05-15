class CreateEquifaxIdmatrixRequest < ActiveRecord::Migration
  def self.up
    create_table :equifax_idmatrix_requests do |t|
      t.integer :ref_id
      t.text :xml
      t.text :soap
      t.text :access
      t.text :entity
      t.text :enquiry
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :equifax_idmatrix_requests
  end
end