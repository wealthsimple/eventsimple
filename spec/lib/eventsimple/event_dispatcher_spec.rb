module Eventsimple
  RSpec.describe EventDispatcher do
    describe '.dispatch' do
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

      let(:sync_reactor) {
        instance_double(UserComponent::Reactors::Created::SyncReactor, call: true)
      }
      let(:async_reactor) {
        instance_double(UserComponent::Reactors::Created::AsyncReactor, call: true)
      }

      before do
        allow(UserComponent::Reactors::Created::SyncReactor).to receive(:new).
          and_return(sync_reactor)
        allow(UserComponent::Reactors::Created::AsyncReactor).to receive(:new).
          and_return(async_reactor)
      end

      it 'triggers sync reactors' do
        described_class.dispatch(event)

        expect(sync_reactor).to have_received(:call)
      end

      it 'enqueues async reactors' do
        described_class.dispatch(event)

        expect(ReactorWorker.jobs.size).to eq(1)
        expect(ReactorWorker.jobs.first['args']).to eq(
          [
            event.to_global_id.to_s,
            "UserComponent::Reactors::Created::AsyncReactor",
          ],
        )
      end
    end
  end
end
