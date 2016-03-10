Before('@google_sign_in') do
  OmniAuth.config.test_mode = true

  mock_auth_hash = {
    'provider':'google_oauth2',
    'uid': '12345',
    'info': {
      'name':'Test user',
      'email':'testgoogle@example.com'
      }
  }
OmniAuth.config.add_mock(:google_oauth2, mock_auth_hash)
end

After('@google_sign_in') do
  OmniAuth.config.test_mode = false
end