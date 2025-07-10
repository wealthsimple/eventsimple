# frozen_string_literal: true

RSpec.describe UserComponent::Events::Created do
  describe '#create' do
    subject(:create_event) { event.save }

    let(:canonical_id) { SecureRandom.uuid }

    let(:user) { User.new }
    let(:event) do
      described_class.new(
        user: user,
        data: {
          canonical_id: canonical_id,
          username: 'test-user', # gitleaks:allow
          email: 'test@example.com',
        },
      )
    end

    it_behaves_like 'an event which synchronously dispatches',
      UserComponent::Reactors::Created::SyncReactor

    it_behaves_like 'an event which synchronously dispatches',
      UserComponent::Reactors::Created::SyncReactor,
      UserComponent::Reactors::Created::SyncReactor2

    it 'updates the user properties' do
      create_event

      expect(user.canonical_id).to eq(event.data.canonical_id)
      expect(user.username).to eq(event.data.username)
      expect(user.email).to eq(event.data.email)

      expect(user.created_at).to eq(event.created_at)
      expect(user.updated_at).to eq(event.created_at)
    end

    context 'when can_apply? check fails' do
      let(:user) { create(:user, canonical_id: canonical_id) }

      it_behaves_like 'an event in invalid state'
    end
  end
end
