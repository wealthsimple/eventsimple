require 'active_job/arguments'

module ActiveJob
  module Arguments
    extend self

    def deserialize_global_id(hash)
      # For non database based processors like sidekiq, the reactor may trigger before the
      # transaction is committed. Attempt to wait for the transaction to be commited before
      # running the reactor. This is not a perfect solution, but it's better than nothing.
      if Eventsimple.configuration.retry_reactor_on_record_not_found
        Retriable.with_context(:reactor) do
          ApplicationRecord.uncached { GlobalID::Locator.locate hash[GLOBALID_KEY] }
        end
      else
        GlobalID::Locator.locate hash[GLOBALID_KEY]
      end
    end
  end
end
