# Eventable
[![Github Actions Badge](https://github.com/wealthsimple/eventable/actions/workflows/main.yml/badge.svg)](https://github.com/wealthsimple/eventable/actions)

## What
Eventable implements a simple deterministic event driven system using ActiveRecord and Sidekiq.

Use Eventable to:

* Add Event Sourcing to your ActiveRecord models.
* Implement Pub/Sub.
* Implement a transactional outbox.
* Store audit logs of changes to your ActiveRecord objects.

Eventable uses standard Rails features like [Single Table Inheritance](https://api.rubyonrails.org/classes/ActiveRecord/Inheritance.html) and [Optimistic Locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html) to implement a simple event driven system.
Async workflows are handled using [Sidekiq](https://github.com/sidekiq/sidekiq).

Typical events in Eventable are ActiveRecord models using STI and look like this:

```ruby
 <UserComponent::Events::Created
  id: 1,
  aggregate_id: 'user-123',
  type: "Created",
  data: {
    name: "John doe",
    email: "johndoe@example.com",
  },
  created_at: 2022-01-01T00:00:00.000000,
  updated_at: 2022-01-01T00:00:00.000000,
 >

<UserComponent::Events::Deleted
  id: 1,
  aggregate_id: 'user-123',
  type: "Deleted",
  created_at: 2022-01-01T00:30:00.000000,
  updated_at: 2022-01-01T00:30:00.000000,
 >
 ```

## Setup

Add the following line to your Gemfile:

```
gem 'eventable'
```
Then run `bundle install`

The eventable UI allows you to view and navigate event history. Add the following line to your routes.rb to use it:

```
mount Eventable::Engine => '/eventable'
```

Generate a migration and add `Eventable` to an existing ActiveRecord model.

```ruby
bundle exec rails generate eventable:event User
```

This will result in the following changes:

```ruby
# ActiveRecord Classes
class User < ApplicationRecord
  extend Eventable::Entity
  event_driven_by UserEvent, aggregate_id: :id
end

class UserEvent < ApplicationRecord
  extend Eventable::Event
  drives_events_for User, events_namespace: 'UserComponent::Events', aggregate_id: :id
end
# Change aggregate_id to the column that represents the unique primary key for your model.

# Data migration
create_table :user_events do |t|
  # Change this to string if your aggregates primary key is a string type
  t.bigint :aggregate_id, null: false, index: true
  t.string :idempotency_key, null: true
  t.string :type, null: false
  t.json :data, null: false, default: {}
  t.json :metadata, null: false, default: {}

  t.timestamps

  t.index :idempotency_key, unique: true
end

add_column :users, :lock_version, :integer
```

Adding lock_version to the model enables [optimistic locking](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html) and protects against concurrent updates to stale versions of the model. Eventable will automatically retry on concurrency failures.

`events_namespace` is an optional argument pointing to the directory where your events classes are defined. If you do not specify this argument, Eventable will store the full namespace of the event classes in the STI type column.

### Event Table definition

| Column  | Description |
| ------------- | ------------- |
| aggregate_id  | Stores the primary key of the entity. |
| idempotency_key  | Optional value which can be used to write events that have uniqueness constraints.  |
| type  | Used by rails to implement Single Table inheritance. Stores the event class name. |
| data  | Stores the event payload |
| metadata  | Stores optional metadata associated with the event |

## Usage

An example event:

```ruby
module UserComponent
  module Events
    class Created < UserEvent
      # Optional: Rails by default will use JSON serialization for the data attribute. Use Eventable::DataType to serialize/deserialize the data attribute using the Message subclass below which uses dry-struct.
      attribute :data, Eventable::DataType.new(self)

      class Message < Eventable::Message
        attribute :canonical_id, DryTypes::Strict::String
        attribute :email, DryTypes::Strict::String
      end

      # Optional: Context specific validations that can be extended onto the model on event creation.
      validates_with UserForm

      # Optional: Implement state machine checks to determine if the event is allowed to be written.
      # Will raise Eventable::InvalidTransition on failure.
      def can_apply?(user)
        user.new_record?
      end

      # Optional: Update the state of your model based on data in the event payload.
      def apply(user)
        user.canonical_id = data.canonical_id
        user.email = data.email

        user
      end
    end
  end
end
```

Write an event:

```ruby
user = User.new

UserComponent::Events::Created.create(
  user: user,
  data: { canonical_id: 'user-123', email: 'johndoe@example.com' },
  metadata: { actor_id: 'user-123' } # optional metadata
)

if user.errors.any?
  # render user errors
else
  # render success
end
```

### Using Dry::Struct
  The Eventable::Message class is a subclass of Dry::Struct. Some common options you can use are:

```ruby
class Message < Eventable::Message
  # attribute key is required and can not be nil
  attribute :canonical_id, DryTypes::Strict::String

  # attribute key is required but can be nil
  attribute :required_key, DryTypes::Strict::String.optional

  # attribute key is not required and can also be nil
  attribute? :optional_key, DryTypes::Strict::String.optional

  # use default value if attribute key is missing or if value is nil
  # Note this is not the typical behaviour for dry-struct and is a customization in the Eventable::Message class.
  attribute :default_key, DryTypes::Strict::String.default('default')
end
```

### Event Reactors

Callback to events can be defined as reactors in the dispatcher class.
Reactors may be `async` or `sync`, depending on the usecase.

#### Sync Reactors
Sync reactors are executed within the context of the event transaction block.
They should **only** contain business logic that make additional database writes.

This is because executing writes to other data stores, e.g API call or writes to kafka/sqs, will result in the transaction being non-deterministic.

#### Async Reactors
Async reactors are executed via Sidekiq. Eventable implements checks to enforce reliable eventually consistent behaviour.

Use Async reactors to kick off async workflows or writes to external data sources as a side effect of model updates.

Reactor example:

```ruby
# Register your dispatch class in an initializer.
Eventable.configure do |config|
  config.dispatchers = %w[
    UserComponent::Dispatcher
  ]
end

# Register reactors in the dispatcher class.
class UserComponent::Dispatcher < Eventable::EventDispatcher
  # one to one
  on UserComponent::Events::Created,
    async:  UserComponent::Reactors::Created::SendNotification

  # or many to many
  on [
    UserComponent::Events::Locked,
    UserComponent::Events::Unlocked
  ], sync: [
    UserComponent::Reactors::Locking::UpdateLockCounter,
    UserComponent::Reactors::Locking::UpdateLockMetrics
  ]
end

# Reactor classes accept the event as the only argument in the constructor
# and must define a `call` method
module UserComponent::Reactors::Created
  class SendNotification
    def initialize(event)
      @event = event
      @user = event.aggregate
    end
    attr_reader :event, :user

    def call
      # do something
    end
  end
end
```

## Configuring an outbox consumer

For many use cases, async reactors are sufficient to handle workflows like making an API call or publishing to a message broker.
However since reactors use Sidekiq, order is not guaranteed.

Eventable provides an outbox implementation with order and eventual consistency guarantees.

**Caveat**: The current implementation leverages a single advisory lock to guarantee write order. This will significantly impact write throughput on the model. On a standard Aurora instance for example, write throughput is limited to ~300 events per second.

For more information on why an advisory lock is required:
https://github.com/pawelpacana/account-basics

### Setup an ordered outbox

Generate migration to setup the outbox cursor table. This table is used to track cursor positions.

```ruby
  bundle exec rails g eventable:outbox:install
```

Create a consummer and processor class for the outbox.
Note: The presence of the consumer class moves all writes to the respective events table to be written using an advisory lock.

Only a single outbox consumer per events table is supported. **DO NOT** create multiple consumers for the same events table.

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
      Rails.logger.info("PROCESSING EVENT: #{event.id}")
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

## Helper methods
Some convenience methods are provided to help with common use cases.

**`#reproject(at: nil)`**

Reproject an entity from events (rebuilds in memory but does not persist the entity).

```ruby
module UserComponent
  module Events
    class Created < UserEvent
      # ...

      def apply(user)
        user.email = data.email

        # Changes the projection to start tracking a sign up timestamp.
        user.signed_up_at = self.created_at
      end
    end
  end
end

user = User.find_by(canonical_id: 'user-123')
user.reproject
user.changes # => { sign_up_at: [nil, "2022-01-01 00:00:00 UTC"] }
user.save!
```

Or reproject the model to inspect what it looked like at a particular point in time.
```ruby
user = User.find_by(canonical_id: 'user-123')
user.reproject(at: 1.day.ago)
user.changes
```

**`#projection_matches_events?`**

Verify that a reprojection of the model matches it's current state.

```ruby
user = User.find_by(canonical_id: 'user-123')
user.update(name: 'something_else')
user.projection_matches_events? => false
```

**`.ignored_for_projection`**

Skip properties on a model that are not managed by the event driven system. This will prevent a reset of the value in case of a reprojection.
Useful if the model that is being event driven has some properties that are managed through other mechanics.

`id` and `lock_version` columns are always ignored by default.

```ruby
  class User
    self.ignored_for_projection = %i[last_sign_in_at]
  end
```

## Common Use cases

### I want to add validations to my model.

You _can_ add conditional validations to the model as usual. For example to verify an email:

```ruby
class User
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

  validates :email, presence: true, format: {
    with: EMAIL_REGEX
  }, if: :email_changed?

  validate :allowed_emails, if: :email_changed?

  def allowed_emails
    return if EmailBlacklist.allowed?(email)

    errors.add(:email, :invalid, value: email)
  end
end
```

However, conditional validations tend to become more complex over time. An alternative approach be to validate at the point _when_ a handle is being updated.

Consider extending the model with a mixin, to apply the validation only when the email is actually being set.

```ruby
module UpdateEmailForm
  def self.extended(base)
    base.class_eval do
      EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

      validates :email, presence: true, format: {
        with: EMAIL_REGEX
      }

      validate :allowed_emails, if: :email_changed?

      def allowed_emails
        return if EmailBlacklist.allowed?(email)

        errors.add(:email, :invalid, value: email)
      end
  end
end

user = User.find_by(canonical_id: 'user-123')

UserComponent::Events::EmailUpdated.create(user: user, data: { email: 'email' })
```

You can configure mixins in the event class itself, so that they are applied automatically at the point of event creating. The following example will extend the user with UpdateEmailForm on user create:

```ruby
class UserComponent::Events::Created < UserEvent
  ...

  validates_with UpdateEmailForm

  ...
end
```

### I want to modify an existing event by adding a new attribute
New attributes should always be added as being either optional or required with a default value.

```ruby
class UserComponent::Events::Created < Eventable::Message
  attribute :new_attribute_1, DryTypes::Strict::String.default('default')
  attribute? :new_attribute_2, DryTypes::Strict::String.optional
end
```

This guarantees compatibility with older events which do not contain this attribute. Old events will be loaded with the attribute being either nil or the new default.

To ensure old models are also in a consistent state, a data migration may be required to update the new attribute to the new default.

```ruby
# migration file
add_column :users, :new_attribute_1, :string, default: 'new_default'

User.where(new_attribute_1: nil).find_in_batches do |batch|
  batch.update_all(new_attribute_1: 'new_default')
end
```

### I want to modify an event by removing a unused attribute
Simply remove the attribute in code and any usage references. Any persisted data in old events will be ignored going forward, so a data migration is not explicitly needed.

However if this is something that is required, we can follow up code removal with a data migration like:

```ruby
UserEvent.where(type: 'MyEventName').in_batches do |batch|
  batch.update_all("data = data::jsonb - 'old_attribute_1' - 'old_attribute_2'")
end
```

### I want to remove an event that is not longer required
* If an event and any properties it sets are no longer required, we can delete the Event, any code references and the model columns.
* The persisted events will be ignored going forward, so a data migration is not explicitly needed.

However if this is something that is required, we can follow up code removal with a data migration like:

```ruby
  # Remove all code references and then run the following migration:

  UserEvent.where(type: 'MyEventName').in_batches do |batch|
    batch.delete_all
  end
```

### I want to ignore InvalidTransition errors

The InvalidTransition error is raised when the `can_apply?` method of an Event returns `false`. In many cases this indicates a bug in the code, but in some cases it is expected behaviour.

An example scenario for not wanting to raise the error is when the `can_apply?` method is primarily defending against redundant events from being written, perhaps when consuming messages from a message broker.

You can mute these errors by calling `rescue_invalid_transition` on the event class. This will cause the event to be ignored and the model to remain unchanged. Optionally, you can pass a block to handle the error.

```ruby
module FooComponent
  module Events
    class BarToTrue < FooEvent
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

### Credits
Special credits to [kickstarter](https://kickstarter.engineering/event-sourcing-made-simple-4a2625113224) and [Eventide Project](https://github.com/eventide-project) for much of the inspiration for this gem.
