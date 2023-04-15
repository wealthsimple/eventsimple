module UserComponent
  module Reactors
    module Created
      class AsyncReactor
        def initialize(event)
          @event = event
        end

        def call; end
      end
    end
  end
end
