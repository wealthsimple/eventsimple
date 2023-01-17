module Eventable
  class AuthController < ApplicationController
    # Step 1 – Redirect the Browser to Okta
    def redirect
      # Setup session state for the authorization request
      setup_auth_session

      # Generate the Okta GET /authorize endpoint URL
      endpoint_url = request_auth_url

      # Redirect to Okta endpoint URL
      redirect_to endpoint_url, allow_other_host: true
    rescue StandardError => e
      render plain: "The authentication request failed. [#{e.message}]"
    end

    # Step 2 - Callback from Okta as a GET request (redirect)
    def callback
      # Validate that the session state matches the original authorization request
      validate_callback_state
      # Validate that no errors were returned from Okta
      validate_callback_error

      # Call the Okta GET /token endpoint to retrieve the access token and id token
      access_token = request_token

      # Decode the id token (JWT) to extra the body hash
      id_token = decode_id_token access_token: access_token

      # Validate the session state with the id token (nonce)
      validate_id_token_nonce(id_token: id_token)

      # Extract the subject and email claims from the id token into the session
      session[:used_id] = id_token['sub']
      session[:email] = id_token['email']

      # Redirect to the original URL
      redirect_to session[:redirect]
    rescue StandardError => e
      render plain: "The authentication request failed. [#{e.message}]"
    end

    private

    def client
      @client ||= OpenIDConnect::Client.new(
        # Client ID from the Application configured in Okta
        identifier: 'OKTA_APP_CLIENT_ID',

        # Client Secret from the Application configured in Okta
        secret: 'OKTA_APP_CLIENT_SECRET',

        # Full URL to AuthController#callback to be configured in Okta
        redirect_uri: 'AUTH_CONTROLLER_CALLBACK_URL',

        # Host name of Wealthsimple Okta Tenant (static)
        host: 'OKTA_TENANT_HOSTNAME',

        # Okta Authorize Endpoint Path (static)
        authorization_endpoint: '/oauth2/v1/authorize',

        # Okta Request Token Endpoint Path (static)
        token_endpoint: '/oauth2/v1/token',
      )
    end

    def request_auth_url
      client.authorization_uri(
        scope: [:openid, :email],
        state: session[:state],
        nonce: session[:nonce],
      )
    end

    def request_token
      client.authorization_code = params[:code]
      client.access_token!
    rescue StandardError
      raise 'request_token_failed'
    end

    def decode_id_token(access_token:)
      # Retrieve the JWKS with public signing key
      jwks = request_jwks
      algorithms = jwks.pluck(:alg).compact.uniq

      # Decode and validate the id token JWT
      id_token = JWT.decode access_token.id_token, nil, true, algorithms: algorithms, jwks: jwks

      # Normalize the result to return JWT body portion of the id token
      id_token[0]
    rescue StandardError
      raise 'decode_token_failed'
    end

    def request_jwks
      # Retrieve the JWKS with the public JWT signing key from a "well-known" URL
      uri = URI('OKTA_TENANT_JWKS_URL')
      json = Net::HTTP.get(uri)

      # Normalize and ensure only signature keys returned
      jwks = JWT::JWK::Set.new(JSON.parse(json))
      jwks.filter! { |key| key[:use] == 'sig' }
      jwks
    end

    def setup_auth_session
      redirect_url = params[:redirect]
      raise 'redirect_url_require' if redirect_url.nil?

      session[:redirect] = redirect_url
      session[:state] = SecureRandom.hex(16)
      session[:nonce] = SecureRandom.hex(16)
    end

    def validate_callback_error
      error = params[:error]
      raise error if error.present?
    end

    def validate_callback_state
      state = params[:state]
      raise 'invalid_state' if state != session[:state]
    end

    def validate_id_token_nonce(id_token:)
      raise 'id_token_nonce_invalid' if id_token['nonce'] != session[:nonce]
    end
  end
end
