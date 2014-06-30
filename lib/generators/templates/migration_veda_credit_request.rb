class CreateVedaCreditRequest < ActiveRecord::Migration
  def self.up
    create_table :veda_credit_requests do |t|
      t.text :xml
      t.text :access
      t.text :service
      t.text :entity
      t.text :bureau_reference
      t.text :enquiry
      t.timestamps
    end
  end
  
  def self.down
    drop_table :veda_credit_requests
  end
end