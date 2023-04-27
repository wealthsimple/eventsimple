module UserComponent
  module Reactors
    module Created
      class BrokenAsyncReactor
        def initialize(event)
          @event = event
        end

        def call
          raise 'Oh noes'
        end

        def self.retries_exhausted(msg, err)
          puts 'time for a nap'
        end
      end
    end
  end
end
