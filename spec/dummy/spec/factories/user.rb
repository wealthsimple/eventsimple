# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    canonical_id { SecureRandom.uuid }
    username { 'test-user' }
    email { 'test@example.com' }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
