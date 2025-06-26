# frozen_string_literal: true

module UserComponent
  class Dispatcher < Eventsimple::Dispatcher
    on(
      Events::Created,
      sync: [
        Reactors::Created::SyncReactor,
        Reactors::Created::SyncReactor2,
      ],
      async: Reactors::Created::AsyncReactor2,
    )
    on Events::RescuedInvalidTransition, sync: Reactors::Created::SyncReactor
    on Events::RescuedInvalidTransitionWithReraise, sync: Reactors::Created::SyncReactor

    on Events::Created, async: Reactors::Created::AsyncReactor
  end
end
