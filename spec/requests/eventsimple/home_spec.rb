# frozen_string_literal: true

RSpec.describe "Home", type: :request do
  describe "GET /eventsimple" do
    it "returns http success" do
      get "/eventsimple"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Eventsimple')
      expect(response.body).to include('User')
    end
  end
end
