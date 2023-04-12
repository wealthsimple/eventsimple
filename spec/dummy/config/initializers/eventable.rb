Eventable.configure do |config|
  config.max_concurrency_retries = 3
  config.dispatchers = %w[
    UserComponent::Dispatcher
  ]
end
