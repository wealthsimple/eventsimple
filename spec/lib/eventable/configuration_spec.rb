RSpec.describe Eventable::Configuration do
  subject(:config) { described_class.new }

  describe '#max_concurrency_retries' do
    it 'defaults to 2' do
      expect(config.max_concurrency_retries).to eq(2)
    end

    it 'can be set to a different value' do
      config.max_concurrency_retries = 3

      expect(config.max_concurrency_retries).to eq(3)
    end

    it 'raises an error when set to a non-positive integer' do
      expect { config.max_concurrency_retries = 0 }.to raise_error(ArgumentError)
      expect { config.max_concurrency_retries = '1' }.to raise_error(ArgumentError)
    end
  end
end
