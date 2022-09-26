module UserComponent
  module Reactors
    module Created
      class SyncReactor
        def initialize(event)
          @event = event
        end

        def call; end
      end
    end
  end
end
