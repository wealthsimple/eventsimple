# frozen_string_literal: true

FactoryBot.define do
  factory :user_event do
    user
    type { 'Created' }
    data {
      {
        canonical_id: SecureRandom.uuid,
        username: 'test-user', # gitleaks:allow
        email: 'test@example.com',
      }
    }
  end
end
