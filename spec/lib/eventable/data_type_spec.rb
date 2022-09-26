RSpec.describe Eventable::DataType do
  subject { described_class.new(event_klass) }

  let(:event_klass) { UserComponent::Events::Created }

  describe '#cast_value' do
    context 'with value as string' do
      let(:value) { { canonical_id: 'user-123' }.to_json }

      it 'returns the typed Message' do
        message = subject.cast_value(value)
        expect(message).to be_an_instance_of(event_klass::Message)
        expect(message.canonical_id).to eq('user-123')
      end
    end

    context 'with value as hash' do
      let(:value) { { canonical_id: 'user-123' } }

      it 'returns the typed Message' do
        message = subject.cast_value(value)
        expect(message).to be_an_instance_of(event_klass::Message)
        expect(message.canonical_id).to eq('user-123')
      end
    end

    context 'with value as instance of Message' do
      let(:value) { UserComponent::Events::Created::Message.new({ canonical_id: 'user-123' }) }

      it 'returns the typed Message' do
        message = subject.cast_value(value)
        expect(message).to eq(value)
      end
    end

    context 'when no Message exists for event' do
      let(:event_klass) { UserComponent::Events::Deleted }
      let(:value) { { canonical_id: 'user-123' }.to_json }

      it 'returns the decoded Hash' do
        message = subject.cast_value(value)
        expect(message).to eq({ canonical_id: 'user-123' }.as_json)
      end
    end
  end

  describe '#serialize' do
    context 'with value as a Hash' do
      let(:json) { { canonical_id: 'user-123' } }
      let(:value) { json }

      it 'returns the typed Message' do
        serialized = subject.serialize(value)
        expect(serialized).to be_an_instance_of(String)
        expect(serialized).to eq(json.to_json)
      end
    end

    context 'with value as instance of Message' do
      let(:json) { { canonical_id: 'user-123' } }
      let(:value) { UserComponent::Events::Created::Message.new(json) }

      it 'returns the typed Message' do
        serialized = subject.serialize(value)
        expect(serialized).to be_an_instance_of(String)
        expect(serialized).to eq(json.to_json)
      end
    end

    context 'with value as a String' do
      let(:value) { { canonical_id: 'user-123' }.to_json }

      it 'returns the typed Message' do
        serialized = subject.serialize(value)
        expect(serialized).to eq(value)
      end
    end
  end

  describe '#deserialize' do
    let(:value) { { canonical_id: 'user-123' }.to_json }

    it 'returns the typed Message' do
      message = subject.deserialize(value)

      expect(message).to be_an_instance_of(event_klass::Message)
      expect(message.canonical_id).to eq('user-123')
    end

    context 'when no Message exists for event' do
      let(:value) { {}.to_json }
      let(:event_klass) { UserComponent::Events::Deleted }

      it 'returns a Hash' do
        message = subject.deserialize(value)

        expect(message).to be_an_instance_of(Hash)
        expect(message).to eq({})
      end
    end
  end
end
