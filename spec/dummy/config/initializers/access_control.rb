require 'access-control'

AccessControl.configure do |config|
  config.header_acl_jwt_key = 'X-Wealthsimple-ACL' # optional
  config.jwt_secret = Rails.application.secrets.fetch(:jwt_secret) # needs to match the value in auth-service depending on app_env
  config.use_client_identifers = false # set if microservice uses client ('client-12345abcd') canonical IDs instead of user ('user-12345abcd') canonical IDs to associate ownership

  # Optional unless making Auth-Service calls (#accessible_owners and #owner_accessible? methods)
  config.api_base_url = Rails.application.secrets.fetch(:auth_service).fetch(:base_url)
  config.app_name = Rails.application.secrets.fetch(:app_name)
  config.app_env = Rails.application.secrets.fetch(:app_env)
  config.timeout_seconds = 10

  config.resolve_ownership do |record|
    {
      owner_id: record.owner.canonical_id,
    }
  end
end
