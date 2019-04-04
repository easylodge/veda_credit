class RenameTablesToEquifax < ActiveRecord::Migration
  def self.up
    rename_table :veda_credit_consumer_requests, :equifax_credit_consumer_requests  if (ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_requests')  && !(ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_requests')
    rename_table :veda_credit_consumer_responses, :equifax_credit_consumer_responses if (ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_responses') && !(ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_responses')

    rename_table :veda_credit_commercial_requests, :equifax_credit_commercial_requests  if (ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_requests')  && !(ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_requests')
    rename_table :veda_credit_commercial_responses, :equifax_credit_commercial_responses if (ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_responses') && !(ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_responses')
  end

  def self.down
    rename_table :equifax_credit_consumer_requests, :veda_credit_consumer_requests  if (ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_requests')  && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_requests')
    rename_table :equifax_credit_consumer_responses, :veda_credit_consumer_responses if (ActiveRecord::Base.connection.table_exists? 'equifax_credit_consumer_responses') && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_consumer_responses')

    rename_table :equifax_credit_commercial_requests, :veda_credit_commercial_requests  if (ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_requests')  && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_requests')
    rename_table :equifax_credit_commercial_responses, :veda_credit_commercial_responses if (ActiveRecord::Base.connection.table_exists? 'equifax_credit_commercial_responses') && !(ActiveRecord::Base.connection.table_exists? 'veda_credit_commercial_responses')
  end
end
