module EquifaxIdmatrix
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      
      source_root File.expand_path("../../templates", __FILE__)
      desc "Sets up the Equifax Idmatrix Configuration File"

      def self.next_migration_number(dirname)
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      end
      
      def create_migration_file
        #copy migration
        migration_template "migration_equifax_idmatrix_request.rb", "db/migrate/create_equifax_idmatrix_request.rb"
        sleep 1
        migration_template "migration_equifax_idmatrix_response.rb", "db/migrate/create_equifax_idmatrix_response.rb"
        
      end
    end
  end
end