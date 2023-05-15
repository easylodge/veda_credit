class CreateEquifaxCreditCommercialResponse < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_responses'
      create_table :equifax_credit_commercial_responses do |t|
        t.text      :headers
        t.integer   :code
        t.text      :xml
        t.boolean   :success
        t.integer   :commercial_request_id
        t.text      :as_hash
        t.string    :client_reference_number
        t.timestamps
      end
    end
  end

  def self.down
    drop_table :equifax_credit_commercial_responses if ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_responses'
  end
end
