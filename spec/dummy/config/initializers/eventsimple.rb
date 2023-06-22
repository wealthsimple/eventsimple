Eventsimple.configure do |config|
  config.max_concurrency_retries = 3
  config.dispatchers = %w[
    UserComponent::Dispatcher
  ]
  config.retry_reactor_on_record_not_found = true
end
