module EquifaxCredit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)
      desc 'Sets up the Equifax Credit Configuration File'

      # def copy_config
      #   template 'equifax_credit.yml', 'config/equifax_credit.yml'
      # end

      def self.next_migration_number(dirname)
        Time.new.utc.strftime('%Y%m%d%H%M%S')
      end

      def create_migration_file
        # copy migration
        migration_template 'migration_equifax_credit_request.rb', 'db/migrate/create_equifax_credit_request.rb'
        sleep 1
        migration_template 'migration_equifax_credit_response.rb', 'db/migrate/create_equifax_credit_response.rb'
        sleep 1
        migration_template 'migration_equifax_credit_commercial_request.rb', 'db/migrate/create_equifax_credit_commercial_request.rb'
        sleep 1
        migration_template 'migration_equifax_credit_commercial_response.rb', 'db/migrate/create_equifax_credit_commercial_response.rb'
        sleep 1
        migration_template 'migration_rename_table.rb', 'db/migrate/rename_equifax_table.rb'
      end
    end
  end
end
