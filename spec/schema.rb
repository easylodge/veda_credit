ActiveRecord::Schema.define do
self.verbose = false

  create_table :veda_credit_requests do |t|
    t.text :xml
    t.text :access
    t.text :product
    t.text :entity
    t.text :enquiry
    t.timestamps
  end

  create_table :veda_credit_responses  do |t|
    t.text :headers
    t.integer :code
    t.text :xml
    t.text :struct
    t.boolean :success
    t.integer :request_id
    t.timestamps
  end
end
