RSpec.describe "Models", type: :request do
  describe "GET /eventsimple/models/:id" do
    it "returns http success" do
      get "/eventsimple/models/User"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Eventsimple')
      expect(response.body).to include('User')
      expect(response.body).to include('Time')
      expect(response.body).to include('Identifier')
      expect(response.body).to include('Event')
      expect(response.body).to include('Filter attribute')
      expect(response.body).to include('username')
    end
  end
end
