When(/^I follow "([^"]*)" it creates new user$/) do |link|
  expect{ click_link(link)}.to change{User.count}.by(1)
end

When(/^I follow "([^"]*)" it does not create new user$/) do |link|
  expect{ click_link(link)}.to_not change{User.count}
end

Given(/^invalid credentials$/) do
  OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
end
