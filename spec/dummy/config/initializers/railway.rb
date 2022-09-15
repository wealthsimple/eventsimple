module Ws
  module Eventable
    Datadog::Statsd.configure
    Datadog::Tracer.configure
    Rollbar.configure(enabled: true)
    Pheme.configure
    Sidekiq.configure
  end
end
