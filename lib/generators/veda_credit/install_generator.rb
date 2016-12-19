module VedaCredit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)
      desc 'Sets up the Veda Credit Configuration File'

      # def copy_config
      #   template 'veda_credit.yml', 'config/veda_credit.yml'
      # end

      def self.next_migration_number(dirname)
        Time.new.utc.strftime('%Y%m%d%H%M%S')
      end

      def create_migration_file
        # copy migration
        migration_template 'migration_veda_credit_request.rb', 'db/migrate/create_veda_credit_request.rb'
        sleep 1
        migration_template 'migration_veda_credit_response.rb', 'db/migrate/create_veda_credit_response.rb'
        sleep 1
        migration_template 'migration_veda_credit_commercial_request.rb', 'db/migrate/create_veda_credit_commercial_request.rb'
        sleep 1
        migration_template 'migration_veda_credit_commercial_response.rb', 'db/migrate/create_veda_credit_commercial_response.rb'
        sleep 1
        migration_template 'migration_rename_table.rb', 'db/migrate/rename_veda_table.rb'
      end
    end
  end
end
