# frozen_string_literal: true

require "eventsimple/version"
require "eventsimple/engine"

require 'active_model'
require 'active_job'
require 'active_support'
require 'dry-types'
require 'dry-struct'
require 'retriable'
require 'sidekiq'

require 'dry_types'

require 'eventsimple/configuration'
require 'eventsimple/message'
require 'eventsimple/data_type'
require 'eventsimple/metadata_type'
require 'eventsimple/metadata'
require 'eventsimple/dispatcher'
require 'eventsimple/event_dispatcher'
require 'eventsimple/reactor_worker'
require 'eventsimple/invalid_transition'

require 'eventsimple/entity'
require 'eventsimple/event'

require 'eventsimple/generators/install_generator'
require 'eventsimple/generators/outbox/install_generator'

module Eventsimple
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
