module UserComponent
  module Dispatch
    extend ActiveSupport::Concern

    included do
      on Events::Created, sync: Reactors::Created::SyncReactor
    end
  end
end
