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

  def create_valid_mock_hash(mock)
    OmniAuth.config.add_mock(:google_oauth2, mock)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  def create_invalid_mock_hash(opts={})
    new_hash = mock_auth_hash.merge(opts)
    OmniAuth.config.add_mock(:google_oauth2, new_hash)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  before(:each) do
    # explicitly tell Devise which mapping to use because in testing
    # we are bypassing the router
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#google_oauth2" do

    context 'with valid oauth authentication' do
      let(:mock) { mock_auth_hash() }
      before do
        create_valid_mock_hash(mock)
      end
      
      context "when user does not exist" do
        
        it "should successfully create a user" do
          expect { post :google_oauth2 }.to change{ User.count }.by(1)
   
          user = User.find_by(email: mock[:info][:email])
          expect(user.email).to eq(mock[:info][:email])
          expect(user.name).to eq(mock[:info][:name])
          expect(user.uid).to eq(mock[:uid])
          expect(user.provider).to eq(mock[:provider])
          expect(user.login).to eq(mock[:uid])
          expect(user.role).to eq(User::CONTESTER)
        end

        it "should redirect to edit_user_path" do
          post :google_oauth2
          expect(response).to redirect_to(edit_user_path(User.find_by(email: mock[:info][:email])))
        end

        it "should set a :notice and :error flash" do
          post :google_oauth2
          expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
          expect(flash[:error]).to eq "Данните в профила Ви не са пълни. Моле попълнете липсващите данни."
        end
      end

      context "when user exists with the same uid and provider" do
        let(:user_with_uid_provider) do
          attributes_for(:user).merge(uid: mock[:uid], provider: mock[:provider])
        end
        
        it "should not create a user" do
          User.create(user_with_uid_provider)
          expect { post :google_oauth2 }.to_not change{ User.count }
        end

        it "should set a :notice flash" do
          User.create(user_with_uid_provider)
          post :google_oauth2
          expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
        end
      end

      context "when user exists with the same email" do
        let(:user_with_email) do
          attributes_for(:user).merge(email: mock[:info][:email])
        end
        before { User.create(user_with_email) }

        it "should not create a user" do
          post :google_oauth2
          expect { post :google_oauth2 }.to_not change{ User.count }
        end

        it "should set a :notice flash" do
          post :google_oauth2
          expect(flash[:notice]).to eq "Успешно оторизиран чрез Google профил."
        end

        it "should update uid and provider" do
          post :google_oauth2
          user = User.find_by(email: user_with_email[:email])
          expect(user.uid).to eql(mock[:uid])
          expect(user.provider).to eql(mock[:provider])
        end
      end
    end
    
    context "with invalid oauth authentication" do
      before do
        create_invalid_mock_hash
      end

      it "should not create user - invalid email" do
        opts = {'info':{'email': '1234'}}
        create_invalid_mock_hash(opts)
        expect { post :google_oauth2 }.to_not change{ User.count }
      end

      it "should not create user - missing uid" do
        opts = {'uid': ""}
        create_invalid_mock_hash(opts)
        expect { post :google_oauth2 }.to_not change{ User.count }
      end

      it "should not create user - missing name" do
        opts = {'info':{'name': ""}}
        create_invalid_mock_hash(opts)
        expect { post :google_oauth2 }.to_not change{ User.count }
      end

      it "should set flash[:error] and redirect_to /login" do
        opts = {'info':{'email': ""}}
        create_invalid_mock_hash(opts)
        expect { post :google_oauth2 }.to_not change{ User.count }
        expect(flash[:error]).to eq "Не успяхме да ви оторизираме чрез Google поради невалидни данни"
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end