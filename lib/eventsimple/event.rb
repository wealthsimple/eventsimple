module Eventsimple
  module Event
    require 'globalid'
    include GlobalID::Identification

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def drives_events_for(aggregate_klass, aggregate_id:, events_namespace: nil, filter_attributes: nil)
      class_attribute :_events_namespace
      self._events_namespace = events_namespace

      class_attribute :_aggregate_klass
      self._aggregate_klass = aggregate_klass

      class_attribute :_aggregate_id
      self._aggregate_id = aggregate_id

      class_attribute :_outbox_mode
      class_attribute :_outbox_concurrency

      class_attribute :_on_invalid_transition
      self._on_invalid_transition = ->(error) { raise error }

      class_attribute :_filter_attributes
      self._filter_attributes = Array.wrap(filter_attributes)

      self.inheritance_column = :type
      self.store_full_sti_class = false

      attribute :metadata, MetadataType.new
      attr_writer :skip_dispatcher
      attr_writer :skip_apply_check

      belongs_to _aggregate_klass.model_name.element.to_sym,
        foreign_key: :aggregate_id,
        primary_key: _aggregate_id,
        class_name: _aggregate_klass.name.to_s,
        inverse_of: :events,
        autosave: false,
        validate: false

      default_scope { order('created_at ASC') }

      before_validation :extend_validation
      after_validation :perform_transition_checks
      before_create :apply_and_persist
      after_create :dispatch

      include InstanceMethods
      extend ClassMethods
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    module InstanceMethods
      def skip_dispatcher
        @skip_dispatcher || false
      end

      def skip_apply_check
        @skip_apply_check || false
      end

      # Apply the event to the aggregate passed in. The default behaviour is a no-op
      def apply(aggregate); end

      def can_apply?(_aggregate)
        true
      end

      def apply_timestamps(aggregate)
        aggregate.created_at ||= created_at
        aggregate.updated_at = created_at
      end

      def perform_transition_checks
        return if skip_apply_check
        return if can_apply?(aggregate)

        _on_invalid_transition.call(
          Eventsimple::InvalidTransition.new(self.class),
        )

        raise ActiveRecord::Rollback
      end

      def extend_validation
        validate_form = self.class.instance_variable_get(:@validate_with)
        self.aggregate = aggregate.extend(validate_form) if validate_form
      end

      # Apply the transformation to the aggregate and save it.
      def apply_and_persist
        apply_timestamps(aggregate)
        apply(aggregate)

        # Persist!
        aggregate.save!

        self.aggregate = aggregate
      end

      def dispatch
        EventDispatcher.dispatch(self) unless skip_dispatcher
      end

      def aggregate
        public_send(_aggregate_klass.model_name.element)
      end

      def aggregate=(aggregate)
        public_send("#{_aggregate_klass.model_name.element}=", aggregate)
      end
    end

    module ClassMethods
      def validate_with(form_klass)
        @validate_with = form_klass
      end

      def rescue_invalid_transition(&block)
        self._on_invalid_transition = block || ->(error) {}
      end

      # We don't store the full namespaced class name in the events table.
      # Events for an entity are expected to be namespaced under _events_namespace.
      def find_sti_class(type_name)
        if _events_namespace.blank?
          super(type_name)
        else
          super("#{_events_namespace}::#{type_name}")
        end
      end

      # Use a no-op deleted class for events that no longer exist in the codebase
      def sti_class_for(type_name)
        super
      rescue ActiveRecord::SubclassNotFound
        klass_name = "Deleted__#{type_name.demodulize}"
        return const_get(klass_name) if const_defined?(klass_name)

        # NOTE: this should still update the timestamps for the model to prevent
        #       projection drift (since the original projection will
        #       have the timestamps applied for the deleted event).
        klass = Class.new(self)

        const_set(klass_name, klass)
      end

      # We want to automatically retry writes on concurrency failures. However events with sync
      # reactors may have multiple nested events that are written within the same transaction.
      # We can only catch and retry writes when they the outermost event encapsulating the whole
      # transaction.
      def create(*args, &block)
        with_locks do
          with_retries(args) { super }
        end
      end

      def create!(*args, &block)
        with_locks do
          with_retries(args) { super }
        end
      end

      def with_locks(&block)
        if _outbox_mode
          base_class.with_advisory_lock(base_class.name, { transaction: true }, &block)
        else
          yield
        end
      end

      def with_retries(args, &block) # rubocop:disable Metrics/AbcSize
        entity = args[0][_aggregate_klass.model_name.element.to_sym]

        # Only implement retries when the event is not already inside a transaction.
        if entity&.persisted? && !existing_transaction_in_progress?
          Retriable.with_context(:optimistic_locking, on_retry: proc { entity.reload }, &block)
        else
          yield
        end
      rescue ActiveRecord::StaleObjectError => e
        raise e unless existing_transaction_in_progress?

        raise e, "#{e.message} No retries are attempted when already inside a transaction."
      end

      def existing_transaction_in_progress?
        ActiveRecord::Base.connection.transaction_open?
      end
    end
  end
end
