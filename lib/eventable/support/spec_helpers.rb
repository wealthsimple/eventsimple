# frozen_string_literal: true

RSpec.shared_examples 'an event which synchronously dispatches' do |dispatcher_klass|
  specify do
    reactors = Dispatcher.rules.for(described_class.new)

    expect(reactors.sync).to include(dispatcher_klass)
  end
end

RSpec.shared_examples 'an event which asynchronously dispatches' do |dispatcher_klass|
  specify do
    reactors = Dispatcher.rules.for(described_class.new)

    expect(reactors.async).to include(dispatcher_klass)
  end
end

RSpec.shared_examples 'an event in invalid state' do
  it 'raises an InvalidTransition error' do
    expect { event.save }.to raise_error(Eventable::InvalidTransition).and not_change(
      event.class, :count
    )
  end
end
