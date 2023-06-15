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
  end
end
