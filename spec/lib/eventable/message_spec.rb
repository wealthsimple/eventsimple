RSpec.describe Eventable::Message do
  let(:subject) { MockMessage }

  class MockMessage < Eventable::Message
    attribute :name, DryTypes::Strict::String.default('leo')
  end

  it 'inherits from Dry::Struct' do
    expect(described_class).to be < Dry::Struct
  end

  it 'sets default for missing key' do
    result = subject.new
    expect(result.name).to eq('leo')
  end

  it 'sets default for key set to nil' do
    result = subject.new(name: nil)
    expect(result.name).to eq('leo')
  end

  it 'overrides default when key is set' do
    result = subject.new(name: 'leonard')
    expect(result.name).to eq('leonard')
  end

  context '#inspect' do
    it 'returns self as json' do
      result = subject.new.inspect
      expect(result['name']).to eq('leo')
    end
  end
end


