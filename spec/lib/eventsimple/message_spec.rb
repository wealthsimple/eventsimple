RSpec.describe Eventsimple::Message do
  before do
    mock_message = Class.new(described_class) do
      attribute :name, DryTypes::Strict::String.default('leo')
    end
    stub_const('MockMessage', mock_message)
  end

  it 'inherits from Dry::Struct' do
    expect(MockMessage).to be < Dry::Struct
  end

  it 'sets default for missing key' do
    result = MockMessage.new
    expect(result.name).to eq('leo')
  end

  it 'sets default for key set to nil' do
    result = MockMessage.new(name: nil)
    expect(result.name).to eq('leo')
  end

  it 'overrides default when key is set' do
    result = MockMessage.new(name: 'leonard')
    expect(result.name).to eq('leonard')
  end

  describe '#inspect' do
    it 'returns self as json' do
      result = MockMessage.new.inspect
      expect(result['name']).to eq('leo')
    end
  end
end
