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

  describe '.event_driven_by' do
    context 'when aggregate_id mismatch between entity and event' do
      let(:event_class) do
        Class.new(ApplicationRecord) do
          extend Eventsimple::Event

          drives_events_for User, aggregate_id: :id, events_namespace: 'UserComponent::Events'
        end
      end

      it 'raises argument error' do
        expect { event_class }.to(raise_error(ArgumentError, 'aggregate_id mismatch event:id entity:canonical_id'))
      end
    end

    context 'when aggregate_id column type mismatch between entity and event' do
      let(:event_class) do
        Class.new(ApplicationRecord) do
          def self.name
            'UserEvent'
          end

          def self.column_for_attribute(column_name)
            return Struct.new(:type).new(:int) if column_name == :aggregate_id
            super
          end

          extend Eventsimple::Event

          drives_events_for User, aggregate_id: :canonical_id, events_namespace: 'UserComponent::Events'
        end
      end

      it 'raises argument error' do
        expect { event_class }.to(raise_error(ArgumentError, 'column type mismatch - event:string entity:int'))
      end
    end
  end
end
