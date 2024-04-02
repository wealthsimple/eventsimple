module Common
  class AccountServiceApplicationRecord < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
    self.abstract_class = true
  end
end
