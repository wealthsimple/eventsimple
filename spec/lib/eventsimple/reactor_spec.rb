# frozen_string_literal: true

RSpec.describe Eventsimple::Reactor do
  include ActiveJob::TestHelper
  include RSpec::Rails::TaggedLoggingAdapter

  it 'has a queue name of :eventsimple', type: :job do
    expect(described_class.queue_name).to eq('eventsimple')
  end

  context 'with uncommited event' do
    let!(:event) do
      UserComponent::Events::Created.new(
        id: '100000',
        user: User.new,
        data: {
          canonical_id: SecureRandom.uuid,
          username: 'test', #gitleaks:allow
          email: 'test@example.com',
        },
      )
    end

    it 'discards the job after retries' do
      expect_any_instance_of(UserComponent::Reactors::Created::AsyncReactor).not_to receive(:call)

      perform_enqueued_jobs {
        UserComponent::Reactors::Created::AsyncReactor.perform_later(
          event,
        )
      }
    end
  end

  context 'with commited event' do
    let!(:event) do
      UserComponent::Events::Created.create(
        user: User.new,
        data: {
          canonical_id: SecureRandom.uuid,
          username: 'test', #gitleaks:allow
          email: 'test@example.com',
        },
      )
    end

    it 'runs the reactor' do
      expect_any_instance_of(UserComponent::Reactors::Created::AsyncReactor).to receive(:call)

      perform_enqueued_jobs {
        UserComponent::Reactors::Created::AsyncReactor.perform_later(
          event,
        )
      }
    end
  end
end
