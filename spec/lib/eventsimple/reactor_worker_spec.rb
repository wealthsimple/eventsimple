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
  let(:reactor) { instance_double(reactor_class, call: true) }
  let(:perform) { described_class.new.perform(event_global_id, reactor_class.to_s) }

  before do
    allow(reactor_class).to receive(:new).and_return(reactor)
    allow(Rails.logger).to receive(:error)
  end

  it 'runs the reactor' do
    perform

    expect(reactor).to have_received(:call).with(event)
  end

  context 'when the event is not found' do
    let(:event_global_id) { "gid://dummy/UserComponent::Events::Created/missing" }

    it 'does not run the reactor' do
      perform

      expect(reactor).not_to have_received(:call)
      expect(Rails.logger).to have_received(:error)
    end
  end
end
