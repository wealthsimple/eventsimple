# frozen_string_literal: true

RSpec.describe UserComponent::Events::OverrideTimestamp do
  describe '#create' do
    subject(:create_event) { event.save }

    let(:canonical_id) { SecureRandom.uuid }

    let(:user) { User.new }
    let(:event) do
      described_class.new(
        user: user,
        data: {
          canonical_id: canonical_id,
          created_at: Time.new(2023, 1, 1),
          updated_at: Time.new(2023, 1, 1),
        },
      )
    end

    it 'updates the user properties' do
      create_event

      expect(user.canonical_id).to eq(event.data.canonical_id)
      expect(user.created_at).to eq(event.data.created_at)
      expect(user.updated_at).to eq(event.data.updated_at)
    end
  end
end
