# frozen_string_literal: true

module Eventsimple
  module Reactor
    module ClassMethods
      def retries_exhausted(_msg, _err); end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def call
      raise 'not implemented'
    end
  end
end
