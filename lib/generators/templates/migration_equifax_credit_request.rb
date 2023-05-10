class CreateEquifaxCreditRequest < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'equifax_credit_requests'
      create_table :equifax_credit_requests do |t|
        t.integer :application_id
        t.text :xml
        t.text :access
        t.text :service
        t.text :entity
        t.text :bureau_reference
        t.text :enquiry
        t.timestamps
      end
    end
  end

  def self.down
    drop_table :equifax_credit_requests if ActiveRecord::Base.connection.table_exists? 'equifax_credit_requests'
  end
end
