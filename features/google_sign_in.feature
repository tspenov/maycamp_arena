@google_sign_in
Feature: Sign in with Google

Background:
  Given I am not logged in
  And I am on the login page

Scenario: Register new user and log him in
  When I follow "google-sign-in" it creates new user
  Then I should see "Успешно оторизиран чрез Google профил."
  And I should see "Данните в профила Ви не са пълни. Моле попълнете липсващите данни."
  And I should see "Test user (Изход)"

Scenario: Log user with existing email in db
  Given there is a user with attributes:
    | email                 | testgoogle@example.com    |
    | name                  | Test user                 |
  When I follow "google-sign-in" it does not create new user
  Then I should see "Успешно оторизиран чрез Google профил."
  And I should see "Test user (Изход)"

Scenario: Log user with existing pair of uid and provider in db
  Given there is a user with attributes:
    | name                  | Test user                 |
    | uid                   | 12345                     |
    | provider              | google_oauth2             |
  When I follow "google-sign-in" it does not create new user
  Then I should see "Успешно оторизиран чрез Google профил."
  And I should see "Test user (Изход)"

Scenario: Authentication failure
  Given invalid credentials
  When I follow "google-sign-in" it does not create new user
  Then I should see "Не успяхме да ви оторизираме чрез Google"
  And I should see "Вход"