class CreateVedaCreditResponse < ActiveRecord::Migration
  def self.up
    create_table :veda_credit_responses do |t|
      t.text :headers
      t.integer :code
      t.text :xml
      t.text :as_hash
      t.boolean :success
      t.integer :request_id
      t.timestamps
    end
  end
  
  def self.down
    drop_table :veda_credit_responses
  end
end