RSpec.describe Eventable::Message do

  class MockMessage < Eventable::Message
    attribute :id, DryTypes::Strict::String
    attribute :name, DryTypes::Strict::String.default('leo')
  end

  it 'raises error on missing keys' do
    expect { MockMessage.new }.to raise_error(Dry::Struct::Error)
  end

  it 'transforms input hash into attributes with values, overriding defaults' do
    result = MockMessage.new(id: 'value', name: 'leonard')
    expect(result.id).to eq('value')
    expect(result.name).to eq('leonard')
  end

  it 'sets default for missing key' do
    result = MockMessage.new(id: 'value')
    expect(result.name).to eq('leo')
  end

  it 'sets default for key set to nil' do
    result = MockMessage.new(id: 'value', name: nil)
    expect(result.name).to eq('leo')
  end

  it 'does not set attribute of unexpected keys' do
    result = MockMessage.new(id: 'value', unexpected: 'key')
    expect(result).not_to respond_to(:unexpected)
  end

  context '#inspect' do
    it 'returns self as json' do
      result = MockMessage.new(id: 'value', name: 'leonard').inspect
      expect(result['id']).to eq('value')
      expect(result['name']).to eq('leonard')
    end
  end
end


