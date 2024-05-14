RSpec.describe UserComponent::Consumer do
  subject(:run_consumer) { described_class.run_consumer }

  before do
    allow(described_class).to receive(:sleep) do
      described_class.stop_consumer = true
    end
    allow(described_class._processor_pool[0]).to receive(:call)
    allow(described_class._processor_pool[1]).to receive(:call)
    allow(described_class._processor_pool[2]).to receive(:call)
    allow(described_class._processor_pool[3]).to receive(:call)
    allow(described_class._processor_pool[4]).to receive(:call)
  end

  after do
    described_class.stop_consumer = false
  end

  let!(:event1) { create(:user_event, user: create(:user, canonical_id: '7a5dc301-c982-4871-bd25-a5eadc97113a')) }
  let!(:event2) { create(:user_event, user: create(:user, canonical_id: '0e0ce944-8299-4c55-b58e-c48a766b44c4')) }
  let!(:event3) { create(:user_event, user: create(:user, canonical_id: '9abde676-8a1e-473d-a095-9651ac177b37')) }
  let!(:event4) { create(:user_event, user: create(:user, canonical_id: '65b0303a-5239-4212-9127-a9dc01658e38')) }
  let!(:event5) { create(:user_event, user: create(:user, canonical_id: 'f77a5726-f10e-45c6-92a1-62073f1720d1')) }
  let!(:event5_2) { create(:user_event, user: create(:user, canonical_id: '5cd4914b-e03c-4c20-aaf0-a2b9769fd514')) }

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

    it 'raises an error when no processor class is defined' do
      described_class._processor_klass = nil
      expect { run_consumer }.to raise_error(RuntimeError, 'Eventsimple: No processor defined')
      described_class._processor_klass = UserComponent::EventProcessor.new
    end

    it 'raises an error when no identifier is defined' do
      described_class._identifier = nil
      expect { run_consumer }.to raise_error(RuntimeError, 'Eventsimple: No identifier defined')
      described_class._identifier = 'UserComponent::Consumer'
    end
  end

  describe '.run_consumer' do
    it 'executes processors and records the last processed event position' do
      cursor = Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')
      expect(cursor).to be(0)

      run_consumer

      expect(described_class._processor_pool.size).to eq(5)
      expect(described_class._processor_pool[0]).to have_received(:call).once
      expect(described_class._processor_pool[1]).to have_received(:call).once
      expect(described_class._processor_pool[2]).to have_received(:call).once
      expect(described_class._processor_pool[3]).to have_received(:call).once
      expect(described_class._processor_pool[4]).to have_received(:call).twice

      cursor = Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')
      expect(cursor).to eq(event5_2.id)
    end

    it 'updates the cursor position after each batch' do
      allow(described_class).to receive(:sleep)
      described_class._batch_size = 2

      expect(Eventsimple::Outbox::Cursor).to receive(:set).with('UserComponent::Consumer', event2.id)
      expect(Eventsimple::Outbox::Cursor).to receive(:set).with('UserComponent::Consumer', event4.id)
      expect(Eventsimple::Outbox::Cursor).to receive(:set).with('UserComponent::Consumer', event5_2.id) do
        described_class.stop_consumer = true
      end

      run_consumer

      described_class._batch_size = 1000
    end

    context 'when consumer is stopped while inside batch' do
      it 'does not change cursor position' do
        allow(described_class._processor_pool[4]).to receive(:call) do |e|
          expect(e.id).to be_in([event5.id, event5_2.id])

          described_class.stop_consumer = true if e.id == event5_2.id
        end

        run_consumer

        expect(Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')).to eq(0)
      end
    end

    context 'when any processor raises an exception' do
      it 'does not change cursor position' do
        allow(described_class._processor_pool[4]).to receive(:call) do |e|
          expect(e.id).to be_in([event5.id, event5_2.id])

          raise 'unknown_error' if e.id == event5_2.id
        end

        expect { run_consumer }.to raise_error(RuntimeError, 'unknown_error')

        expect(Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')).to eq(0)
      end
    end

    context 'with an existing cursor' do
      before do
        Eventsimple::Outbox::Cursor.set('UserComponent::Consumer', event2.id)
      end

      it 'starts after the last processed event position' do
        run_consumer

        expect(described_class._processor_pool[0]).not_to have_received(:call)
        expect(described_class._processor_pool[1]).not_to have_received(:call)
        expect(described_class._processor_pool[2]).to have_received(:call).once
        expect(described_class._processor_pool[3]).to have_received(:call).once
        expect(described_class._processor_pool[4]).to have_received(:call).twice

        expect(Eventsimple::Outbox::Cursor.fetch('UserComponent::Consumer')).to eq(event5_2.id)
      end
    end
  end
end
