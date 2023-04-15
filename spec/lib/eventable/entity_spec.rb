module Eventable
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

    describe '#projection_matches_events?' do
      it 'returns true if the entity matches its events' do
        expect(user.projection_matches_events?).to be true

        user.update(username: 'changed', updated_at: 1.day.ago)

        expect(user.projection_matches_events?).to be false
      end
    end

    describe '#reproject' do
      it 'reprojects the entity from its events' do
        user.reproject
        expect(user.changes).to be_empty

        original_user = User.find_by(id: user.id)

        user.update(username: 'changed', updated_at: 1.day.ago)

        user.reproject
        expect(user.changes.keys).to eq(['username', 'updated_at'])
        user.save!

        expect(
          original_user.attributes.except(*Entity::DEFAULT_IGNORE_PROPS),
        ).to eq(
          user.attributes.except(*Entity::DEFAULT_IGNORE_PROPS),
        )
      end
    end
  end
end
