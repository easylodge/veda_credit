class CreateVedaCreditCommercialRequest < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_requests'
      create_table :veda_credit_commercial_requests do |t|
        t.integer :ref_id
        t.text :xml
        t.text :access
        t.text :service
        t.text :entity
        t.text :enquiry
        t.timestamps
      end
    end
  end
  
  def self.down
    drop_table :veda_credit_commercial_requests if ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_requests'
  end
end