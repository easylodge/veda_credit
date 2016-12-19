ActiveRecord::Schema.define do
  self.verbose = false

  create_table :veda_credit_commercial_requests do |t|
    t.integer :ref_id
    t.text :xml
    t.text :access
    t.text :service
    t.text :entity
    t.text :bureau_reference
    t.text :enquiry
    t.timestamps
  end

  create_table :veda_credit_commercial_responses do |t|
    t.text :headers
    t.integer :code
    t.text :xml
    t.boolean :success
    t.text :as_hash
    t.integer :commercial_request_id
    t.timestamps
  end

  create_table :veda_credit_consumer_requests do |t|
    t.integer :ref_id
    t.text :xml
    t.text :access
    t.text :service
    t.text :entity
    t.text :bureau_reference
    t.text :enquiry
    t.timestamps
  end

  create_table :veda_credit_consumer_responses do |t|
    t.text :headers
    t.integer :code
    t.text :xml
    t.text :as_hash
    t.boolean :success
    t.integer :consumer_request_id
    t.timestamps
  end
end
