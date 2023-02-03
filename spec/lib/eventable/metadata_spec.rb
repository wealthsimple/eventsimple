RSpec.describe Eventable::Metadata do
  it 'inherits from Message' do
    expect(described_class).to be < Eventable::Message
  end

  it 'has no required attributes' do
    expect { described_class.new }.not_to raise_error
  end

  it 'supports an actor_id as a string' do
    result = described_class.new(actor_id: 'id')
    expect(result.actor_id).to eq('id')
  end

  it 'supports a reason as a string' do
    result = described_class.new(reason: 'the reason')
    expect(result.reason).to eq('the reason')
  end

  it 'raises error on unexpected keys' do
    expect { described_class.new(unexpected: 'key') }.to raise_error
  end
end

