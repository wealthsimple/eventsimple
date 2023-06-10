Eventsimple.configure do |config|
  config.max_concurrency_retries = 3
  config.dispatchers = %w[
    UserComponent::Dispatcher
  ]
  config.active_job_parent_klass = 'ApplicationJob'
end
