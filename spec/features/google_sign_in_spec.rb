require 'awesome_print'

feature 'User signs in with google' do

  before(:each) do
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    #OmniAuth.config.mock_auth[:google_oauth2] = nil
    
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

  scenario "Register new user and log him in" do
    visit '/login'
    
    expect(page).to have_text('Вход')
    expect(page).to have_css('img.google-sign-in')

    expect{
      click_link('google-sign-in')
    }.to change{User.count}.by(1)

    expect(page).to have_text("Успешно оторизиран чрез Google профил.")
    expect(page).to have_text("Данните в профила Ви не са пълни. Моле попълнете липсващите данни.")

    expect(page).to have_text("Test user")
    expect(page).to have_text("Изход")
  end

  scenario "Log user with existing email in db" do
    expect { 
      user = User.create(
        email: "testgoogle@example.com", 
        login: "test_google",
        unencrypted_password: "secret",
        unencrypted_password_confirmation: "secret",
        role: "contester",
        name: "Test user",
        city: "Айтос"
        )
    }.to change{User.count}.by(1)

    visit '/login'

    expect(page).to have_text('Вход')
    expect(page).to have_css('img.google-sign-in')

    expect{
      click_link('google-sign-in')
    }.to change{User.count}.by(0)

    expect(page).to have_text("Успешно оторизиран чрез Google профил.")
    expect(page).to have_text("Test user")
    expect(page).to have_text("Изход")

  end

  scenario "Log user with existing pair of uid and provider in db" do
    #OmniAuth.config.add_mock(:google_oauth2, mock_auth_hash)

    expect { 
      user = User.create(
        email: "test123@example.com",
        login: "test_google123",
        unencrypted_password: "secret",
        unencrypted_password_confirmation: "secret",
        role: "contester",
        name: "Test user",
        city: "Айтос",
        uid: "12345",
        provider: "google_oauth2"
        )
    }.to change{User.count}.by(1)

    visit '/login'

    expect(page).to have_text('Вход')
    expect(page).to have_css('img.google-sign-in')

    expect{
      click_link('google-sign-in')
    }.to change{User.count}.by(0)

    expect(page).to have_text("Успешно оторизиран чрез Google профил.")
    expect(page).to have_text("Test user")
    expect(page).to have_text("Изход")

  end

  scenario "Authentication failure" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    visit '/login'

    expect(page).to have_text('Вход')
    expect(page).to have_css('img.google-sign-in')

    expect{
      click_link('google-sign-in')
    }.to change{User.count}.by(0)

    expect(page).to have_text("Не успяхме да ви оторизираме чрез Google")
  end

end