# frozen_string_literal: true

RSpec.describe UserComponent::Events::Created do
  describe '#create' do
    subject(:create_event) { event.save }

    let(:user) { User.new }
    let(:event) do
      described_class.new(
        user: user,
        data: {
          canonical_id: SecureRandom.uuid,
        },
      )
    end

    it_behaves_like 'an event which synchronously dispatches',
      UserComponent::Reactors::Created::SyncReactor

    it 'updates the user properties' do
      create_event

      expect(user.canonical_id).to eq(event.data.canonical_id)

      expect(user.created_at).to eq(event.created_at)
      expect(user.updated_at).to eq(event.created_at)
    end

    context 'when user is already created' do
      let(:user) {
        User.create(
          canonical_id: SecureRandom.uuid,
          created_at: Time.current,
          updated_at: Time.current,
        )
      }

      it_behaves_like 'an event in invalid state'
    end
  end
end