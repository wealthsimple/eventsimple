module Eventable
  module Event
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def drives_events_for(model_klass, events_namespace: nil, aggregate_id: :canonical_id)
      class_attribute :_events_namespace
      self._events_namespace = events_namespace

      class_attribute :_model_klass
      self._model_klass = model_klass

      class_attribute :_aggregate_id
      self._aggregate_id = aggregate_id

      class_attribute :_outbox_mode
      class_attribute :_outbox_concurrency

      self.inheritance_column = :type
      self.store_full_sti_class = false

      attribute :metadata, MetadataType.new
      attr_writer :skip_dispatcher
      attr_writer :skip_apply_check

      belongs_to _model_klass.model_name.element.to_sym,
        foreign_key: :aggregate_id,
        primary_key: _aggregate_id,
        class_name: _model_klass.name.to_s,
        inverse_of: :events,
        autosave: false,
        validate: false

      default_scope { order('created_at ASC') }

      around_save :with_database_role
      before_validation :extend_validation
      validate :_valid?
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

      def with_database_role(&block)
        ApplicationRecord.connected_to(role: :writing, &block)
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

      def _valid?
        return if skip_apply_check
        return if can_apply?(aggregate)

        raise Eventable::InvalidTransition
      end

      def extend_validation
        validate_form = self.class.instance_variable_get(:@validate_with)
        self.aggregate = aggregate.extend(validate_form) if validate_form
      end

      # Apply the transformation to the aggregate and save it.
      def apply_and_persist
        apply(aggregate)
        apply_timestamps(aggregate)

        # Persist!
        aggregate.save!

        self.aggregate = aggregate
      end

      def dispatch
        Dispatcher.dispatch(self) unless skip_dispatcher
      end

      def aggregate
        public_send(_model_klass.model_name.element.to_s)
      end

      def aggregate=(aggregate)
        public_send("#{_model_klass.model_name.element}=", aggregate)
      end
    end

    module ClassMethods
      def validate_with(form_klass)
        @validate_with = form_klass
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

      # We want to automatically retry writes on concurrency failures. However events with sync
      # reactors may have multiple nested events that are writen within the same transaction.
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
        entity = args[0][_model_klass.model_name.element.to_sym]

        # Only implement retries when the event is not already inside a transaction.
        if entity && !ActiveRecord::Base.connection.transaction_open?
          Retriable.retriable(
            on: ActiveRecord::StaleObjectError,
            intervals: [0, 0],
            on_retry: proc {
              Rails.logger.info("Retrying event #{name} #{_model_klass.model_name.element} #{entity&.canonical_id}")
              entity.reload
            },
            &block
          )
        else
          yield
        end
      end
    end
  end
end
