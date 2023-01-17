RSpec.describe "Models", type: :request do
  describe "GET /eventable/models/:id" do
    it "returns http success" do
      get "/eventable/models/User"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Eventable')
      expect(response.body).to include('User')
      expect(response.body).to include('Time')
      expect(response.body).to include('Identifier')
      expect(response.body).to include('Event')
    end
  end
end
