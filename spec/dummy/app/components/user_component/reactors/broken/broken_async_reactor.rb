module UserComponent
  module Reactors
    module Broken
      class BrokenAsyncReactor
        include Eventsimple::Reactor

        def initialize(event)
          @event = event
        end

        def call
          raise 'Oh noes'
        end

        def self.retries_exhausted(_msg, _err)
          puts 'time for a nap'
        end
      end
    end
  end
end
