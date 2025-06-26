# frozen_string_literal: true

module Eventsimple
  RSpec.describe EventDispatcher do
    include ActiveJob::TestHelper

    describe '.dispatch', type: :job do
      let(:event) do
        UserComponent::Events::Created.create(
          user: User.new,
          data: {
            canonical_id: SecureRandom.uuid,
            username: 'test',
            email: 'test@example.com',
          },
          skip_dispatcher: true,
        )
      end

      it 'triggers sync reactors' do
        allow(UserComponent::Reactors::Created::SyncReactor).to receive(:perform_now)

        described_class.dispatch(event)

        expect(UserComponent::Reactors::Created::SyncReactor).to have_received(:perform_now).with(event)
      end

      it 'enqueues async reactors' do
        expect { described_class.dispatch(event) }.to have_enqueued_job(
          UserComponent::Reactors::Created::AsyncReactor,
        ).with(event).at(:no_wait)
      end
    end

    describe '.rules' do
      describe '#for' do
        it 'returns the sync reactors in the order in which they were registered' do
          expected_reactors = [
            UserComponent::Reactors::Created::SyncReactor,
            UserComponent::Reactors::Created::SyncReactor2,
          ]
          expect(described_class.rules.for(UserComponent::Events::Created.new).sync).to eq expected_reactors
        end

        it 'returns the async reactors in the order in which they were registered' do
          expected_reactors = [
            UserComponent::Reactors::Created::AsyncReactor2,
            UserComponent::Reactors::Created::AsyncReactor,
          ]
          expect(described_class.rules.for(UserComponent::Events::Created.new).async).to eq expected_reactors
        end
      end
    end
  end
end
