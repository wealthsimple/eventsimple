# frozen_string_literal: true

require 'rails/generators'

module Eventable
  module Generators
    module Outbox
      class InstallGenerator < Rails::Generators::Base
        include Rails::Generators::Migration

        desc "Generate Outbox Table Migration"
        source_root File.expand_path("templates", __dir__)

        def self.next_migration_number(dirname)
          next_migration_number = current_migration_number(dirname) + 1
          ActiveRecord::Migration.next_migration_number(next_migration_number)
        end

        def copy_migrations
          migration_template "create_outbox_cursor.erb",
            "db/migrate/create_eventable_outbox_cursor.rb",
            migration_version: migration_version
        end

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end
    end
  end
end
