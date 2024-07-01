# frozen_string_literal: true

require "eventsimple/version"
require "eventsimple/engine"


require 'active_model'
require 'active_record'
require 'active_job'
require 'active_support'
require 'dry-types'
require 'dry-struct'
require 'retriable'

require 'dry_types'

# module ActiveRecord
#   module ConnectionAdapters
#     module PostgreSQL
#       module ColumnMethods
#         def xid8(*names, **options)
#           raise ArgumentError, "Missing column name(s) for xid8" if names.empty?
#           names.each { |name| column(name, :xid8, **options) }
#         end
#         # def xid8(name, options = {})
#         #   column(name, :xid8, options)
#         # end
#       end
#     end
#   end
# end
# require 'eventsimple/xid8_type'
require 'eventsimple/active_job/arguments'
require 'eventsimple/configuration'
require 'eventsimple/message'
require 'eventsimple/data_type'
require 'eventsimple/metadata_type'
require 'eventsimple/metadata'
require 'eventsimple/dispatcher'
require 'eventsimple/event_dispatcher'
require 'eventsimple/reactor'
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
