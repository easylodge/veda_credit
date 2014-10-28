class RenameTable < ActiveRecord::Migration
  def self.up
    rename_table :veda_credit_requests,  :veda_credit_consumer_requests  if ((ActiveRecord::Base.connection.table_exists? 'veda_credit_requests')  && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_requests'))
    rename_table :veda_credit_responses, :veda_credit_consumer_responses if ((ActiveRecord::Base.connection.table_exists? 'veda_credit_responses') && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_responses'))

    rename_column :veda_credit_consumer_responses, :request_id, :consumer_request_id
    rename_column :veda_credit_responses, :application_id, :ref_id
    add_column :veda_credit_consumer_responses, :as_hash, :text
  end
  
  def self.down
    rename_table :veda_credit_consumer_requests,  :veda_credit_requests  if ((ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_requests')  && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_requests'))
    rename_table :veda_credit_consumer_responses, :veda_credit_responses if ((ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_responses') && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_responses'))

    rename_column :veda_credit_responses, :consumer_request_id, :request_id
    remove_column :veda_credit_responses, :as_hash, :text
  end
end