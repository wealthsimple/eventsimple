# frozen_string_literal: true

module UserComponent
  module Reactors
    module Created
      class AsyncReactor2 < Eventsimple::Reactor
        def call(event); end
      end
    end
  end
end
