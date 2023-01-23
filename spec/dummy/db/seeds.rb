user = User.new
UserComponent::Events::Created.create(
  user: user,
  data: {
    canonical_id: 'user-123',
    username: 'user',
    email: 'johnsmith@example.com',
  },
)

UserComponent::Events::Updated.create(
  user: user,
  data: {
    email: 'janedoe@example.com',
  },
)
