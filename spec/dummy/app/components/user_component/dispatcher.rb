module UserComponent
  class Dispatcher < Eventable::Dispatcher
    on Events::Created, sync: Reactors::Created::SyncReactor
    on Events::RescuedInvalidTransition, sync: Reactors::Created::SyncReactor
    on Events::RescuedInvalidTransitionWithReraise, sync: Reactors::Created::SyncReactor
  end
end