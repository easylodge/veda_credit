class CreateEquifaxCreditResponse < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_responses'
      create_table :equifax_credit_consumer_responses do |t|
        t.text      :headers
        t.integer   :code
        t.text      :xml
        t.boolean   :success
        t.integer   :consumer_request_id
        t.string    :client_reference_number
        t.text      :as_hash
        t.timestamps
      end
    end
  end

  def self.down
    drop_table :equifax_credit_consumer_responses if ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_responses'
  end
end
