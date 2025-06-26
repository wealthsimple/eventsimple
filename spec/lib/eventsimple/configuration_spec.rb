# frozen_string_literal: true

RSpec.describe Eventsimple::Configuration do
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

  describe '#dispatchers' do
    it 'defaults to an empty array' do
      expect(config.dispatchers).to eq([])
    end

    it 'can be set to an array of strings' do
      config.dispatchers = ['UserComponent::Dispatcher']
      expect(config.dispatchers).to eq([UserComponent::Dispatcher])
    end

    it 'raises an error when set to a non-array' do
      expect { config.dispatchers = 'Eventsimple::EventDispatcher' }.to raise_error(ArgumentError)
    end
  end

  describe '#metadata_klass' do
    it 'defaults to Eventsimple::Metadata' do
      expect(config.metadata_klass).to eq(Eventsimple::Metadata)
    end

    it "raises when class name cannot be constantized" do
      config.metadata_klass = "Eventsimple::OtherClass"
      expect { config.metadata_klass }.to raise_error(NameError)
    end
  end

  describe '#parent_record_klass' do
    it 'defaults to ApplicationRecord' do
      expect(config.parent_record_klass).to eq(ApplicationRecord)
    end

    it "raises when class name cannot be constantized" do
      config.parent_record_klass = "Eventsimple::OtherClass"
      expect { config.parent_record_klass }.to raise_error(NameError)
    end

    it "sets to expected name when changed" do
      config.parent_record_klass = "Common::SecondaryApplicationRecord"
      expect(config.parent_record_klass).to eq(Common::SecondaryApplicationRecord)
    end
  end
end
