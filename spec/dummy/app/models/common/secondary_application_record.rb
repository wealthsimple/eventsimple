# frozen_string_literal: true

module Common
  class SecondaryApplicationRecord < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.abstract_class = true
  end
end
