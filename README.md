# Eventable
[![Github Actions Badge](https://github.com/wealthsimple/eventable/actions/workflows/main.yml/badge.svg)](https://github.com/wealthsimple/eventable/actions)

## What
At a high level Eventable implements a simple deterministic event driven system using ActiveRecord and Sidekiq.

* [**Auditable**](#audit-trails) history of how a model has been updated.
* **Eventual consistency** guarantees with async behaviour using Sidekiq.
* **Established contract** on how models may be updated using Dry Struct.
* **Outbox** - Events can be consumed in order using the build in consumer implementation.

## Why
### Eventual Consitency guarantees

Our typical Sidekiq patterns are non deterministic and lose consistency everytime there is a redis outage.

```ruby
# Using an after_commit hook is not sufficient as it is not guaranteed to run after the transaction is committed. In the case of a redis outage, the after_commit hook will not run.
class User < ApplicationRecord
  after_commit :notify_handle_update, on: :update, if: :handle_changed?

  def notify_handle_update
    NotifyHandleUpdated.perform_async(canonical_id)
  end
end

# Using an after_update callback is not sufficient as it may or may not trigger after the transaction is complete. If the sidekiq job runs before the transaction is committed, the notification will be sent with a stale handle value.
# In the case of a DB outage we risk the job being queued even if the transaction fails.
class User < ApplicationRecord
  after_update :notify_handle_update, if: :handle_changed?

  def notify_handle_update
    NotifyHandleUpdated.perform_async(canonical_id)
  end
end

class NotifyHandleUpdated
  include Sidekiq::Worker

  def perform(canonical_id)
    user = User.find(canonical_id)
    send_notification(user.email, user.handle)
  end

  ...
end
```

Eventable implements [atomic guarantees](#async-reactors) around async flows triggered after an entity change. Async flows (via Sidekiq) are guaranteed to be enqueued as part of a db transaction.

### Audit trails
PaperTrail is a popular tool used to store change history. Compared to Papertrail, Eventable is able to provide more context around changes to a model, with a smaller data footprint.

Also, as events are a representation of state change, they can be replayed to recreate the state of an entity.

PaperTrail in comparison stores the entire serialized entity, which can result in very large datasets.

```ruby
<PaperTrail::Version:0x000055ca6946b458
 id: 33468469,
 item_type: "Person",
 item_id: 41029,
 event: "update",
 whodunnit: nil,
 object:
  "---\nbackup_withholding: false\nfirst_name: Henriette\nlast_name: Sheehan\nmiddle_names: []
  id: 41029\ncanonical_id: person-jslmhlubounegq\npreferred_first_name: Henriette\ngender:
  date_of_birth: 1939-12-21\ncitizenships:\n- CA\nlocale: \njurisdictions:\n- CA
  external_id: dunbrook-226701488\ncreated_at: !ruby/object:ActiveSupport::TimeWithZone
  utc: 2017-11-09 17:26:56.197949000 Z\n  zone: &1 !ruby/object:ActiveSupport::TimeZone
  name: Etc/UTC\n  time: 2017-11-09 17:26:56.197949000 Z
  updated_at: !ruby/object:ActiveSupport::TimeWithZone\n  utc: 2019-06-05 20:33:57.431217000 Z
  zone: *1\n  time: 2019-06-05 20:33:57.431217000 Z\npower_of_attorney_first_name:
  power_of_attorney_last_name: \napplication_family_id: application_family-karney1
  email: dunbrook+Henriette.Sheehan@wealthsimple.com\nuser_id: user-1axl_won0ow
  marital_status: \ncountry_of_birth: \ncommunication_materials: \ntax_residencies:
  household_id: \npermanent_resident: \nvisa_type: \nvisa_expiration_date: \nus_person:
  workplace_restrictions: false\nforeign_tax_resident: false\n",
 created_at: Fri, 16 Apr 2021 20:34:19.470903000 UTC +00:00>
```

```ruby
 <UserComponent::Events::HandleUpdated
  id: 1,
  aggregate_id: 'user-123',
  type: "HandleUpdated",
  data: {
    "handle"=>"bobby",
  },
  metadata: {
    actor_id: 'user-123'
  },
  created_at: 2022-01-01T00:00:00.000000,
  updated_at: 2022-01-01T00:00:00.000000,
 >
 ```

### Concurrency protection
Concurrency protection is baked in by default using [Rails Optimistic Locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html).

Concurrent attempts to update the same entity will automatically be attempted in sequential order.

## Setup

Run generator to generate migrations and add `Eventable` to an existing model.

```ruby
bundle exec rails generate eventable:event User
```

This should result in the following changes:

```ruby
# ActiveRecord Classes
class User < ApplicationRecord
  extend Eventable::Entity
  event_driven_by UserEvent
end

class UserEvent < ApplicationRecord
  extend Eventable::Event
  drives_events_for User, events_namespace: 'UserComponent::Events'
end

# Data migration
create_table :user_events do |t|
  t.string :aggregate_id, null: false, index: true
  t.string :idempotency_key, null: true
  t.string :type, null: false
  t.json :data, null: false, default: {}
  t.json :metadata, null: false, default: {}

  t.timestamps

  t.index :idempotency_key, unique: true
end

add_column :users, :lock_version, :integer
```
Adding lock_version to the model enforces [optimistic locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html) and protects against concurrent updates to the model. Eventable will automatically implement retry logic on concurrency failures.

| Column  | Description |
| ------------- | ------------- |
| aggregate_id  | Stores the primary key of the entity. Defaults to using `canonical_id`. |
| idempotency_key  | Optional value which can be used to write events that have a uniqueness criteria.  |
| type  | Used by rails to implement Single Table inheritance. Stores the event class name. |
| data  | Stores the event payload |
| metadata  | Stores optional event metadata e.g `:actor_id`, `:reason` |

## Using Eventable

Event lifycycle:
![Transaction Verification](/docs/diagrams/event_lifecycle.png?raw=true "Transaction Verification")

An example event:

```ruby
module UserComponent
  module Events
    class HandleUpdated < UserEvent
      # Tells Rails to use the DataType class to serialize/deserialize the data attribute.
      # A Message class is required if this is set.
      # This is optional and if not provided will use the default JSON serializer.
      attribute :data, Eventable::DataType.new(self)

      # Defines the data structure of the event payload using dry-struct
      class Message < Eventable::Message
        attribute :handle, DryTypes::Strict::String
      end

      # Optional context specific validations that can be extended onto the entity on event creation.
      # See example of how these can be constructed below.
      validates_with UserHandleForm

      # Optional state machine checks to determine if the event is allowed to be written.
      # Will raise Eventable::InvalidTransition on failure.
      # E.g Handle update can only happen for existing users, and only if a handle is not already set.
      def can_apply?(user)
        user.persisted? && user.handle.blank?
      end

      # Implement the business logic of updating the user based on the event payload.
      # Optional if writing event is not intended to update the model.
      def apply(user)
        user.handle = data.handle

        user
      end
    end
  end
end
```

### Usage
```ruby
user = User.find_by(canonical_id: 'user-1')

UserComponent::Events::HandleUpdated.create(
  user: user,
  data: { handle: 'handle' },
  metadata: { actor_id: access.current_user_id } # optional metadata
)

if user.errors.any?
  # render user errors
else
  # render success
end
```

### Using Dry::Struct
  Event messages are typed using Dry::Struct. Some common options you can use are:

```ruby
class Message < Eventable::Message
  # attribute is required and can not be nil
  attribute :canonical_id, DryTypes::Strict::String

  # attribute is required but can be nil
  attribute :required_key, DryTypes::Strict::String.optional

  # attribute is not required and can be nil
  attribute? :optional_key, DryTypes::Strict::String.optional

  # attribute will use default value if key is missing or value is nil
  # Note this is not the typical behaviour for dry-struct and is a customization in the BaseMessage class.
  attribute :default_key, DryTypes::Strict::String.default('default')
end
```

### Event Reactors

Callback to events can be defined as reactors in the dispatcher class.
Reactors may be `async` or `sync`, depending on the usecase.

#### Sync Reactors
Sync reactors are executed within the context of the event transaction block.
They should **only** contain business logic that makes additional database writes.

This is because executing writes to other data stores, e.g API call or writes to kafka/sqs, would result in the transaction being non-deterministic.

For example, if writing to kafka, in a case where the transaction rolls back, the write to kafka would not be reversible.

#### Async Reactors
Async reactors are triggered through a Sidekiq Job `ReactorWorker`. The ReactorWorker has checks in place to guarantee a very high degree of reliable idempotent behaviour.
In the case of either postgres or redis outages, async reactors can be expected to be atomic against the event written.

Async reactors should be used to write to external data sources as a sideeffect of model updates. e.g writes to kafka, sqs, redis or an external API.

![Transaction Verification](/docs/diagrams/eventable_verify.png?raw=true "Transaction Verification")

Reactor examples

```ruby
# The dispatcher class allow us to register reactors for events.
class Dispatcher < Eventable::EventDispatcher
  # one to one
  on UserComponent::Events::HandleUpdated,
    async:  UserComponent::Reactors::HandleUpdated::SendNotification

  # or array to array
  on [
    UserComponent::Events::Locked,
    UserComponent::Events::Unlocked
  ], sync: [
    UserComponent::Reactors::Locking::UpdateLockCounter, UserComponent::Reactors::Locking::UpdateLockMetrics
  ]
end

# reactor classes accept the event as the only argument in the constructor
# and should define a `call` method
module UserComponent::Reactors::HandleUpdated
  class SendNotification
    def initialize(event)
      @event = event
      # In the case of a sync reactor, the user will be the updated model right after the event write.
      # In the case of async reactors, the user will be at least as new as right after event write, but may be newer if other events have been written in the time before the Job executes.
      @user = event.user
    end
    attr_reader :event, :user

    def call
      # do something
    end
  end
end
```

## Helper methods

**`#reproject(at: nil)`**

Reproject an entity from events (rebuilds in memory but does not persist the entity).

```ruby
module UserComponent
  module Events
    class HandleUpdated < UserEvent
      # ...

      def apply(user)
        user.handle = data.handle

        # Updating the projection to start tracking the number of times a handle has been updated.
        user.handle_update_count += 1

        user
      end
    end
  end
end

user = User.find_by(canonical: 'user-123')
user.reproject
user.changes # => { handle_update_count: [nil, 1] }
user.save!
```

Or reproject the model to inspect what it looked like at a particular point in time.
```ruby
user = User.find_by(canonical: 'user-123')
user.reproject(at: 1.day.ago)
```

**`#projection_matches_events?`**

Useful when a data migration or code change may have caused a divergence from the event stream, and we want to confirm that the model is still in the correct state.

```ruby
user = User.find_by(canonical: 'user-123')
user.update(handle: 'something_else')
user.projection_matches_events? => false
```

**`.ignored_for_projection`**

Skip properties on a model that are not managed by the event driven system. This will prevent a reset of the value in case of a reprojection.
Useful if the model that is being event driven has some properties that are managed through other mechanics.

`id` and `lock_version` columns are always ignored by default.

```ruby
  class Contact
    # last_payment_at on contact is updated from within the payment flow anytime a payment is made.
    self.ignored_for_projection = %i[last_payment_at]
  end
```

## Configuring an outbox consumer

For many use cases, async reactors are sufficient to handle publishing to message brokers like kafka/sqs.
However since reactors use Sidekiq, order is not guaranteed.

Eventable provides an outbox implementation with order and eventual consistency guarantees.

**Caveat**: The current implementation leverages a single advisory lock to guarantee write order, which reduces write throughput on the events table to ~300 events per second.

A more performant implementation leveraging multiple advisory locks is in the works.

For more information on why an advisory lock is required:
https://github.com/pawelpacana/account-basics

https://github.com/wealthsimple/cash-service/blob/6c7dffa90d75e0f6bf06ba145babd1ec71968912/app/eventide/README.md.

### Setup an ordered outbox

Generate migration to setup the outbox cursor table. This table is used to track the last event that was processed by an outbox consumer.

```ruby
  bundle exec rails g eventable:outbox:install
```

Create a consummer and processor class for the outbox.
Note: The presence of the consumer class triggers all writes to the respective events table to be written under an advisory lock.

Only a single outbox consumer per events table. **DO NOT** create multiple consumers for the same events table.

```ruby
require 'eventable/outbox/consumer'

module UserComponent
  class Consumer
    extend Eventable::Outbox::Consumer

    consumes_event UserEvent
    processor EventProcessor
  end
end
```

```ruby
module UserComponent
  class EventProcessor
    def initialize(event)
      @event = event
    end
    attr_reader :event

    def call
      puts "PROCESSING EVENT: #{event.id}"
    end
  end
end
```

### Usage
Create a rake task to run the consumer

```ruby
  namespace :consumers do
    desc 'Starts the user event outbox consumer'
    task :user_events do
      UserComponent::Consumer.start
    end
  end
```

## Common Use cases

### I want to add validations to my model.

You _can_ add conditional validations to the model as usual. For example to verify a handle format on handle update:

```ruby
class User
  validates :handle, presence: true, format: {
    with: Common::Entities::Client::HANDLE_REGEX
  }, allow_blank: true, if: :handle_changed?

  validate :allowed_handle, if: :handle_changed?

  def allowed_handle
    return unless BlacklistChecker.disallowed_handle?(handle)

    errors.add(:handle, :invalid, value: handle)
  end
end
```

Conditional validations however, tend to become more complex over time. A better way would be validate at the point _when_ a handle is being updated.

Consider extending the model with a mixin, to apply the validation only on handle update.

```ruby
module UpdateHandleForm
  def self.extended(base)
    base.class_eval do
      validates :handle, presence: true, format: {
        with: Common::Entities::Client::HANDLE_REGEX
      }

      validate :allowed_handle
    end

    def allowed_handle
      return unless BlacklistChecker.disallowed_handle?(handle)

      errors.add(:handle, :invalid, value: handle)
    end
  end
end

user = User.find_by(canonical_id: 'canonical_id')
user = user.extend(UpdateHandleForm)

UserComponent::Events::HandleUpdated.create(user: user, data: { handle: 'handle' })
```

Eventable allows setting mixins in the event class itself, so that they are applied  automatically at the point of creating the event. The following example will apply handle validations only on handle update:

```ruby
class UserComponent::Events::HandleUpdated < UserEvent
  ...

  validates_with UpdateHandleForm

  ...
end
```

### I want to modify an existing event by adding a new attribute
New attributes should always be added as being either optional or required with a default value.

```ruby
class UserComponent::Events::HandleUpdated < Eventable::Message
  attribute :new_attribute_1, DryTypes::Strict::String.default('default')
  attribute? :new_attribute_2, DryTypes::Strict::String.optional
end
```

This guarantees compatibility with older events which do not contain this attribute. Old events will be loaded with the attribute being either nil or the default.

To ensure old models are also in a consistent state, make sure to set the default value on any new column on the table.

```ruby
# migration file
add_column :users, :new_attribute_1, :string, default: 'default'

User.where(new_attribute_1: nil).find_in_batches do |batch|
  batch.update_all(new_attribute_1: 'default')
end
```

### I want to modify an event by removing a dead attribute
Simply remove the attribute in code and any usage references. Any persisted data in old events will be ignored going forward, so a data migration is not explicitly needed.

However if removing the attribute info is desired, we can follow up code removal with a data migration:

```ruby
UserEvent.where(type: 'EventTypeName').in_batches do |batch|
  batch.update_all("data = data::jsonb - 'attribute_a' - 'attribute_b'")
end
```

### I want to remove an event that is not longer required
* If an event and any properties it sets are no longer required, we can delete the Event, any code references and the model columns it updates.
* We'll Need to delete the persisted events as well, since Rails will no longer be able to load them.

```ruby
  # Remove all code references and then run the following migration:

  remove_column :users, :handle
  UserEvent.where(type: 'HandleUpdated').delete_all
```

### I want to change how an event is applied and run a backfill
For example if we want to start storing the number of times a handle has been updated
```ruby
module UserComponent
  module Events
    class HandleUpdated < UserEvent
      # ...

      def apply(user)
        user.handle = data.handle

        # We're changing the the projection to start tracking the number of times a handle has been updated.
        user.handle_update_count += 1

        user
      end
    end
  end
end
```

We can approach this in two ways:
* Update the attribute manually on the record using a data migration, so that it reflects the correct value. This can potentially be much faster when dealing with a large dataset.

```ruby
## data migration
add_column :users, :handle_update_count, :integer, default: 0

query = <<-SQL
  WITH counted AS(
    SELECT a.aggregate_id, COUNT(*) AS count
    FROM user_events
    group_by a.canonical_id
    WHERE type = 'HandleUpdated'
  ) UPDATE users
  SET handle_update_count = count
  FROM counted
  WHERE canonical_id = aggregate_id;
SQL
execute query
```

* Reproject the entity from the event stream using the reproject method. This is much simpler, but potentially slower.

```ruby
add_column :users, :handle_update_count, :integer, default: 0

User.find_each do |user|
  user.reproject
  puts user.changes
  user.save!
end
```


### I want to ignore InvalidTransition errors

The InvalidTransition error is raised when the `can_apply?` method of an Event returns `false`. This is an important error to raise for monitoring for invalid state transitions being made.

There are some cases when monitoring for this error isn't helpful and the logging errors it generates are overly aggressive. An example scenario for not wanting to raise the error is when the `can_apply?` method is primarily defending against redundant events from being written, perhaps from a message stream like SQS.

You can use the class method `rescue_invalid_transition` to rescue these errors. The event will not be written as if the rescue wasn't there, it just gives greater control of the error.

```ruby
module FooComponent
  module Events
    class BarToTrue < FooEvent
      # the block is optional
      rescue_invalid_transition do |error|
        logger.info("Receive invalid transition error", error)
      end

      def can_apply?(foo)
        !foo.bar
      end

      def apply(foo)
        foo.bar = true

        foo
      end
    end
  end
end
```
