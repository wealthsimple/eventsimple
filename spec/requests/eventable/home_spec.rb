RSpec.describe "Home", type: :request do
  describe "GET /eventable" do
    it "returns http success" do
      get "/eventable"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Eventable')
      expect(response.body).to include('User')
      expect(response.body).to include('Choose event source model')
    end
  end
end
