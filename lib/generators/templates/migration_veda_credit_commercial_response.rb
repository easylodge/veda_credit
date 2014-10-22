class CreateVedaCreditCommercialResponse < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_responses'
      create_table :veda_credit_commercial_responses do |t|
        t.text :headers
        t.integer :code
        t.text :xml
        t.boolean :success
        t.integer :commercial_request_id
        t.timestamps
      end
    end
  end
  
  def self.down
    drop_table :veda_credit_commercial_responses if ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_responses'
  end
end