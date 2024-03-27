# frozen_string_literal: true

RSpec.shared_examples 'an event which synchronously dispatches' do |dispatcher_klass|
  specify do
    reactors = Eventsimple::EventDispatcher.rules.for(described_class.new)

    expect(reactors.sync).to include(dispatcher_klass)
  end
end

RSpec.shared_examples 'an event which asynchronously dispatches' do |dispatcher_klass|
  specify do
    reactors = Eventsimple::EventDispatcher.rules.for(described_class.new)

    expect(reactors.async).to include(dispatcher_klass)
  end
end

RSpec.shared_examples 'an event in invalid state' do
  it 'raises an InvalidTransition error' do
    expect { event.save }.to raise_error(Eventsimple::InvalidTransition).and not_change(
      event.class, :count
    )
  end

  it 'raises an event with the correct error message' do
    allow(Eventsimple::InvalidTransition).to receive(:new).and_call_original

    expect { event.save }.to raise_error do |e|
      # make a string assertion with match instead of anything
      # use regex pattern
      expect(e.message).to match(/Invalid State Transition for .* on aggregate_id: #{event.aggregate_id}/)
    end
  end
end

RSpec.shared_examples 'an event in invalid state that is rescued' do
  context 'when save' do
    it 'does not InvalidTransition error on save' do
      expect { event.save }.not_to raise_error
    end

    it 'does not write event on save' do
      expect { event.save }.not_to change(event.class, :count)
    end
  end

  context 'when save!' do
    it 'does not InvalidTransition error on save!' do
      expect { event.save! }.not_to raise_error
    end

    it 'does not write event on save!' do
      expect { event.save! }.not_to change(event.class, :count)
    end
  end
end

RSpec::Matchers.define_negated_matcher(:not_change, :change)
