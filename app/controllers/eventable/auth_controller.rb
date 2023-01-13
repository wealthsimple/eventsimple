module Eventable
  class AuthController < ApplicationController
    def redirect
      setup_auth_session
      url = request_auth_url
      redirect_to url, allow_other_host: true
    rescue StandardError => e
      render plain: "The authentication request failed. [#{e.message}]"
    end

    def callback
      validate_callback_state
      validate_callback_error

      request_token
      redirect_to session[:redirect]
    rescue StandardError => e
      render plain: "The authentication request failed. [#{e.message}]"
    end

    private

    def get_client
      Rack::OAuth2::Client.new(
        # Client ID from the Application configured in Okta
        :identifier => 'CLIENT_ID_HERE',

        # Client Secret from the Application configured in Okta
        :secret => 'CLIENT_SECRET_HERE', 

        # Full URL to AuthController#callback to be configured in Okta
        :redirect_uri => 'URL_HERE',

        # Host name of Wealthsimple Okta Tenant (static)
        :host => 'wealthsimple-oie.oktapreview.com',

        # Okta Authorize Endpoint Path (static)
        authorization_endpoint: '/oauth2/v1/authorize',

        # Okta Request Token Endpoint Path (static)
        token_endpoint: '/oauth2/v1/token'
      )
    end

    def request_auth_url
      client = get_client
      client.authorization_uri(
        scope: [:openid, :email],
        state: session[:state],
      )
    end

    def request_token
      client = get_client
      client.authorization_code = params[:code]
      result = client.access_token!
      token = JWT.decode result.token_response[:access_token], nil, false
      session[:used_id] = token[0]['sub']
    rescue StandardError
      raise 'request_token_failed'
    end

    def setup_auth_session
      redirect_url = params[:redirect]
      raise 'redirect_url_require' if redirect_url.nil?

      session[:redirect] = redirect_url
      session[:state] = SecureRandom.hex(16)
    end

    def validate_callback_error
      error = params[:error]
      raise error if error.present?
    end

    def validate_callback_state
      state = params[:state]
      raise 'invalid_state' if state != session[:state]
    end
  end
end
