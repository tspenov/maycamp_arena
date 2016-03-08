require 'awesome_print'
describe Users::OmniauthCallbacksController do
  
  def mock_auth_hash
    {
      'provider':'google_oauth2',
      'uid': '12345',
      'info': {
        'name':'Test user',
        'email':'testgoogle@example.com'
      }
    }
  end

  def create_invalid_mock_hash(opts={})
    new_hash = mock_auth_hash.merge(opts)
    OmniAuth.config.add_mock(:google_oauth2, new_hash)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  before do
    
    request.env["devise.mapping"] = Devise.mappings[:user]

    @mock_auth_hash = {
      'provider':'google_oauth2',
      'uid': '12345',
      'info': {
        'name':'Test user',
        'email':'testgoogle@example.com'
      }
    }
    OmniAuth.config.add_mock(:google_oauth2, mock_auth_hash())
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  
    @user_with_uid_provider = {
      email: "test123@example.com",
      login: "test_google123",
      unencrypted_password: "secret",
      unencrypted_password_confirmation: "secret",
      role: "contester",
      name: "Test user",
      city: "Айтос",
      uid: "12345",
      provider: "google_oauth2"
    }

    @user_with_email = {
      email: "testgoogle@example.com",
      login: "test_google123",
      unencrypted_password: "secret",
      unencrypted_password_confirmation: "secret",
      role: "contester",
      name: "Test user",
      city: "Айтос"
    }
  end

  describe "#google_oauth2" do
    before(:each) do
      User.delete_all
    end

    context "user does not exist" do

      it "should redirect to edit_user_path" do
        post :google_oauth2
        expect(response).to redirect_to(edit_user_path(User.last))
      end

      it "should successfully create a user" do
        expect {
          post :google_oauth2
        }.to change{ User.count }.by(1)

        user = User.last
        mock = mock_auth_hash()
        expect(user.email).to eq(mock[:info][:email])
        expect(user.name).to eq(mock[:info][:name])
        expect(user.uid).to eq(mock[:uid])
        expect(user.provider).to eq(mock[:provider])
        expect(user.login).to eq(mock[:uid])
        expect(user.role).to eq(User::CONTESTER)
      end


      it "should set a :notice and :error flash" do
        post :google_oauth2
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Данните в профила Ви не са пълни. Моле попълнете липсващите данни."
      end
    end

    context "user exists with the same uid and provider" do


      it "should not create a user" do
        User.create(@user_with_uid_provider)
        expect {
          post :google_oauth2
        }.to_not change{ User.count }
      end

      it "should set a :notice flash" do
        User.create(@user_with_uid_provider)
        post :google_oauth2
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
      end

    end

    context "user exists with the same email" do

      it "should not create a user" do
        User.create(@user_with_email)
        expect {
          post :google_oauth2
        }.to_not change{ User.count }
      end

      it "should set a :notice flash" do
        User.create(@user_with_email)
        post :google_oauth2
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
      end

      it "should update uid and provider" do
        User.create(@user_with_email)
        post :google_oauth2
        expect(User.last.uid).to eql("12345")
        expect(User.last.provider).to eql("google_oauth2")
      end
    end

    context "post with invalid data" do
      it "should not create user - invalid email" do
        opts = {'info':{'email': '1234'}}
        create_invalid_mock_hash(opts)
        expect {
          post :google_oauth2
        }.to_not change{ User.count }

      end

      it "should not create user - missing uid" do
        opts = {'uid': ""}
        create_invalid_mock_hash(opts)
        expect {
          post :google_oauth2
        }.to_not change{ User.count }

        
      end

      it "should not create user - missing name" do
        opts = {'info':{'name': ""}}
        create_invalid_mock_hash(opts)
        expect {
          post :google_oauth2
        }.to_not change{ User.count }
      end


      it "should set flash[:error] and redirect_to /login" do
        opts = {'info':{'email': ""}}
        create_invalid_mock_hash(opts)
        post :google_oauth2
        expect(flash[:error]).to be_present
        expect(flash[:error]).to eq "Не успяхме да ви оторизираме чрез Google поради невалидни данни"
        expect(response).to redirect_to(new_session_path)
      end

    end

  end

end