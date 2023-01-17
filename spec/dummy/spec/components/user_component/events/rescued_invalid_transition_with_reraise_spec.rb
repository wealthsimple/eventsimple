# frozen_string_literal: true

RSpec.describe UserComponent::Events::RescuedInvalidTransitionWithReraise do
  describe '#create' do
    subject(:create_event) { event.save }

    let(:canonical_id) { SecureRandom.uuid }

    let(:user) { User.new }
    let(:event) do
      described_class.new(
        user: user,
        data: {
          canonical_id: canonical_id,
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

    context 'when can_apply? check fails' do
      let(:user) {
        User.create(
          canonical_id: canonical_id,
          username: 'test-user',
          email: 'test@example.com',
          created_at: Time.current,
          updated_at: Time.current,
        )
      }

      it_behaves_like 'an event in invalid state'
    end
  end
end
