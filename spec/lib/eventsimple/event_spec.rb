RSpec.describe Eventsimple::Event do
  describe 'event retries' do
    let(:user_canonical_id) { SecureRandom.uuid }
    let(:user) { User.new }

    before do
      UserComponent::Events::Created.create(
        user: user,
        data: {
          canonical_id: user_canonical_id,
          username: 'test',
          email: 'test@example.com',
        },
      )
    end

    context 'when entity is stale' do
      # disable transactional tests so we can test the retry logic
      def self.uses_transaction?(_method) = true
      after { UserEvent.delete_all }

      it 'retries and successfully writes the event' do
        stale_user = User.find_by(canonical_id: user_canonical_id)

        user.enable_writes!
        user.touch

        event = UserComponent::Events::Deleted.create!(user: stale_user)

        expect(stale_user.deleted_at).to eq(event.created_at)
      end

      context 'when event write is already within a transaction' do
        it 'raised stale object error with details' do
          stale_user = User.find_by(canonical_id: user_canonical_id)

          user.enable_writes!
          user.touch

          expect {
            User.transaction do
              UserComponent::Events::Deleted.create!(user: stale_user)
            end
          }.to raise_error(
            ActiveRecord::StaleObjectError,
            'Attempted to update a stale object: User. ' \
            'No retries are attempted when already inside a transaction.',
          )
        end
      end
    end

    context 'when an event class no longer exists' do
      it 'uses a no-op deleted class' do
        UserEvent.create!(type: 'NonExistentEvent', aggregate_id: user_canonical_id)

        event = UserEvent.last
        expect(event).to be_a(UserEvent::Deleted__NonExistentEvent)

        # timestamps should still be updated for deleted events.
        expect(event.created_at).to eq(user.reproject.updated_at)
      end
    end
  end
end
