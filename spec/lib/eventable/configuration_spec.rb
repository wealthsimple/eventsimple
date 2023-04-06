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

  describe '#dispatcher_class' do
    it 'defaults to Dispatcher' do
      expect(config.dispatcher_class).to eq(Dispatcher)
    end

    it 'can be set to a different value' do
      config.dispatcher_class = 'Eventable::EventDispatcher'

      expect(config.dispatcher_class).to eq(Eventable::EventDispatcher)
    end
  end

  describe '#event_classes' do
    it 'defaults to nil' do
      expect(config.event_classes).to be_nil
    end

    it 'can be set to an array of strings' do
      config.event_classes = ['UserComponent::Events::Created', 'UserComponent::Events::Updated']

      expect(config.event_classes).to eq([UserComponent::Events::Created,
                                          UserComponent::Events::Updated])
    end

    it 'can be set to a string and returns an array' do
      config.event_classes = 'UserComponent::Events::Created'
      expect(config.event_classes).to eq([UserComponent::Events::Created])
    end
  end
end
