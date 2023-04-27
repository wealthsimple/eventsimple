module UserComponent
  class Dispatcher < Eventsimple::Dispatcher
    on Events::Created, sync: Reactors::Created::SyncReactor
    on Events::RescuedInvalidTransition, sync: Reactors::Created::SyncReactor
    on Events::RescuedInvalidTransitionWithReraise, sync: Reactors::Created::SyncReactor

    on Events::Created, async: Reactors::Created::AsyncReactor
    on Events::Broken, async: Reactors::Created::BrokenAsyncReactor
  end
end
