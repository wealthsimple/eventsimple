RSpec.describe UserComponent::Consumer do
  subject(:run_consumer) { described_class.run_consumer(group_number: 0) }

  before do
    allow(described_class).to receive(:sleep) do
      described_class.stop_consumer = true
    end
  end

  after do
    described_class.stop_consumer = false
  end

  it 'has an identifier' do
    expect(described_class._identifier).to eq('UserComponent::Consumer')
  end

  it 'consumes an event' do
    expect(described_class._event_klass).to eq(UserEvent)
  end

  it 'has a processor' do
    expect(described_class._processor_klass).to eq(UserComponent::EventProcessor)
  end

  context 'with invalid configuration' do
    it 'raises an error when no event class is defined' do
      described_class._event_klass = nil
      expect { run_consumer }.to raise_error(RuntimeError, 'Eventsimple: No event class defined')
      described_class._event_klass = UserEvent
    end

    it 'raises an error when no processor is defined' do
      described_class._processor = nil
      expect { run_consumer }.to raise_error(RuntimeError, 'Eventsimple: No processor defined')
      described_class._processor = UserComponent::EventProcessor.new
    end

    it 'raises an error when no identifier is defined' do
      described_class._identifier = nil
      expect { run_consumer }.to raise_error(RuntimeError, 'Eventsimple: No identifier defined')
      described_class._identifier = 'UserComponent::Consumer'
    end
  end

  describe '.run_consumer' do
    it 'records the last processed event position' do
      event = create(:user_event)

      cursor = Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer', group_number: 0)
      expect(cursor).to be(0)

      expect(described_class._processor).to receive(:call).once

      run_consumer

      cursor = Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer', group_number: 0)
      expect(cursor).to eq(event.id)
    end

    context 'when consumer is stopped inside batch' do
      let(:user) { create(:user) }
      let!(:events) { create_list(:user_event, 1100, user: user) }

      it 'breaks correctly and sets the cursor to the last processed event position' do
        allow(described_class._processor).to receive(:call) do |e|
          expect(e.id).to be_in(events[0..1].map(&:id))

          # stop consumer after the second event in the batch is processed
          if e.id == events[1].id
            described_class.stop_consumer = true
          end
        end

        run_consumer

        expect(described_class._processor).to have_received(:call).exactly(2).times
        expect(Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')).to eq(events[1].id)
      end
    end

    context 'with an existing cursor' do
      let!(:events) { create_list(:user_event, 5) }

      before do
        Eventsimple::Outbox::Cursor.set('UserComponent::Consumer', events[2].id)
        allow(described_class._processor).to receive(:call)
      end

      it 'starts after the last processed event position' do
        run_consumer

        expect(described_class._processor).to have_received(:call).twice
        expect(Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')).to eq(events[4].id)
      end
    end
  end
end
