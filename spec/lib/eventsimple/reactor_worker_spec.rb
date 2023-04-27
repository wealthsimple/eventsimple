RSpec.describe Eventsimple::ReactorWorker do
  let(:event) {
    UserComponent::Events::Created.create!(
      user: User.new,
      data: {
        canonical_id: SecureRandom.uuid,
        username: 'test',
        email: 'test@example.com',
      },
      skip_dispatcher: true,
    )
  }
  let(:event_global_id) {
    event.to_global_id.to_s
  }
  let(:reactor_class) { UserComponent::Reactors::Created::SyncReactor }
  let(:reactor_class_name) { reactor_class.name }
  let(:reactor) { instance_double(reactor_class, call: true) }
  let(:perform) { described_class.new.perform(event_global_id, reactor_class.to_s) }

  before do
    allow(reactor_class).to receive(:new).and_return(reactor)
    allow(Rails.logger).to receive(:error)
  end

  it 'runs the reactor' do
    perform

    expect(reactor).to have_received(:call)
  end

  context 'when the event is not found' do
    let(:event_global_id) { "gid://dummy/UserComponent::Events::Created/missing" }

    it 'does not run the reactor' do
      perform

      expect(reactor).not_to have_received(:call)
      expect(Rails.logger).to have_received(:error)
    end
  end

  context 'sidekiq_retries_exhausted' do
    let(:ex) { StandardError.new('expected error') }
    let(:msg) {
      {
        'queue' => 'mock_queue',
        'class' => 'mock_name',
        'args' => [event_global_id, reactor_class_name],
        'error_message' => 'An error occured'
      }
    }

    subject(:exhaust_retries) do
      described_class.new.sidekiq_retries_exhausted_block.call(msg, ex)
    end

    before do
      allow(Rails.logger).to receive(:error);
    end

    context 'reactor has a retries exhausted handler' do
      let(:reactor_class) { UserComponent::Reactors::Created::BrokenAsyncReactor }

      before do
        allow(reactor_class).to receive(:retries_exhausted)
      end

      it 'logs a general error' do
        exhaust_retries
        expect(Rails.logger).to have_received(:error).with("Event #{event_global_id} retries exhausted for : #{reactor_class}")
      end

      it 'calls the retries exhausted handler on the reactor' do
        exhaust_retries
        expect(reactor_class).to have_received(:retries_exhausted).with(msg, ex)
      end
    end

    context 'reactor does NOT have a retries exhausted handler' do
      let(:reactor_class) { UserComponent::Reactors::Created::AsyncReactor }

      it 'logs a general error' do
        exhaust_retries
        expect(Rails.logger).to have_received(:error).with("Event #{event_global_id} retries exhausted for : #{reactor_class}")
      end
    end

    context 'reactor can not be found' do
      let(:reactor_class_name) { "Missing::Class" }

      it 'logs a general error' do
        exhaust_retries
        expect(Rails.logger).to have_received(:error).with("Event #{event_global_id} retries exhausted for : Missing::Class")
      end
    end
  end
end
