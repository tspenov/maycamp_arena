require 'awesome_print'
describe Users::OmniauthCallbacksController do
  
  before do
    
    request.env["devise.mapping"] = Devise.mappings[:user]

    mock_auth_hash = {
      'provider':'google_oauth2',
      'uid': '12345',
      'info': {
        'name':'Test user',
        'email':'testgoogle@example.com'
      }
    }
    OmniAuth.config.add_mock(:google_oauth2, mock_auth_hash)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  
  end

  describe "#google_oauth2" do
    
    it "should successfully create a user" do
      expect {
        post :google_oauth2
      }.to change{ User.count }.by(1)
    end
  end


end