# frozen_string_literal: true

module Eventsimple
  RSpec.describe Entity do
    let(:user) { User.new }
    let!(:event) do
      UserComponent::Events::Created.create(
        user: user,
        data: {
          canonical_id: SecureRandom.uuid,
          username: 'test',
          email: 'test@example.com',
        },
      )
    end

    describe '.event_driven_by' do
      context 'when optimistic locking column is missing' do
        let(:user_class) do
          Class.new(ApplicationRecord) do
            def self.name
              'User'
            end

            self.locking_column = :missing_column

            extend Eventsimple::Entity
            event_driven_by UserEvent, aggregate_id: :id
          end
        end

        it 'raises argument error' do
          expect { user_class }.to(raise_error(ArgumentError, "A missing_column column is required to enable optimistic locking"))
        end
      end

      context 'when aggregate_id value mismatch between entity and event' do
        let(:user_class) do
          Class.new(ApplicationRecord) do
            def self.name
              'User'
            end

            extend Eventsimple::Entity

            event_driven_by UserEvent, aggregate_id: :id
          end
        end

        it 'raises argument error' do
          expect { user_class }.to(raise_error(ArgumentError, 'aggregate_id mismatch event:canonical_id entity:id'))
        end
      end

      context 'when aggregate_id column type mismatch between entity and event' do
        let(:user_class) do
          Class.new(ApplicationRecord) do
            def self.name
              'User'
            end

            def self.column_for_attribute(column_name)
              return Struct.new(:type).new(:int) if column_name == :canonical_id

              super
            end

            extend Eventsimple::Entity

            event_driven_by UserEvent, aggregate_id: :canonical_id
          end
        end

        it 'raises argument error' do
          expect { user_class }.to(raise_error(ArgumentError, 'column type mismatch - event:string entity:int'))
        end
      end
    end

    describe '#projection_matches_events?' do
      it 'returns false if the entity no longer matches state from events' do
        expect(user.projection_matches_events?).to be true

        user.enable_writes! do
          user.update!(username: 'changed', updated_at: 1.day.ago)
        end

        expect(user.projection_matches_events?).to be false
      end
    end

    describe '#reproject' do
      it 'reprojects the entity from its events' do
        user.reproject
        expect(user.changes).to be_empty

        original_user = User.find_by(id: user.id)

        user.enable_writes! do
          user.update!(username: 'changed', updated_at: 1.day.ago)

          user.reproject
          expect(user.changes.keys).to eq(%w[username updated_at])
          user.save!
        end

        expect(
          original_user.attributes.except(*Entity::DEFAULT_IGNORE_PROPS),
        ).to eq(
          user.attributes.except(*Entity::DEFAULT_IGNORE_PROPS),
        )
      end
    end

    describe '#enable_writes!' do
      it 'allows writes to the entity' do
        expect(user.readonly?).to be true

        user.enable_writes!
        expect(user.readonly?).to be false
      end

      context 'when enabled with a block' do
        it 'passes self into the block' do
          user.enable_writes! do |entity|
            expect(entity).to eq(user)
          end
        end

        context 'when the entity was readonly before' do
          it 'restores readonly status after the block' do
            user.readonly!

            user.enable_writes! do
              expect(user.readonly?).to be false
            end

            expect(user.readonly?).to be true
          end
        end

        context 'when the entity was not readonly before' do
          it 'restores readonly status after the block' do
            user.enable_writes!

            user.enable_writes! do
              expect(user.readonly?).to be false
            end

            expect(user.readonly?).to be false
          end
        end
      end
    end
  end
end
