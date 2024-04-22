require 'eventsimple/outbox/consumer'

module UserComponent
  class Consumer
    extend Eventsimple::Outbox::Consumer

    identifier 'UserComponent::Consumer'
    consumes_event UserEvent
    processor EventProcessor
  end
end
