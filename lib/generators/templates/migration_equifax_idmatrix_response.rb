class CreateEquifaxIdmatrixResponse < ActiveRecord::Migration
  def self.up
    create_table :equifax_idmatrix_responses do |t|
      t.text :headers
      t.integer :code
      t.text :xml
      t.boolean :success
      t.integer :request_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :equifax_idmatrix_responses
  end
end