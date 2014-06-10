class CreateVedaResponse < ActiveRecord::Migration
  def self.up
    create_table :veda_responses do |t|
      t.text :headers
      t.integer :code
      t.text :xml
      t.text :struct
      t.text :match
      t.integer :request_id

      t.timestamps
    end
  end
  
  def self.down
    drop_table :veda_responses
  end
end