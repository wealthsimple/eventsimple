# frozen_string_literal: true

require 'rails/generators'

module Eventable
  module Generators
    class EventGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Generate Outbox Table Migration"
      source_root File.expand_path("templates", __dir__)

      argument :model_name, type: :string

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "create_events.erb",
          "db/migrate/create_#{model_name.downcase}_events.rb",
          migration_version: migration_version

        template "event.erb",
          "app/models/#{model_name.downcase}_event.rb"

        line = "class #{model_name.camelize} < ApplicationRecord"
        gsub_file "app/models/#{model_name.downcase}.rb", /(#{Regexp.escape(line)})/mi do |match|
          "#{match}\n  extend Eventable::Entity\n  event_driven_by #{model_name.camelize}Event\n"
        end
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
