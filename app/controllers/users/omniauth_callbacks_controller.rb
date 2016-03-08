class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2

    auth = request.env["omniauth.auth"]

    if auth.nil? or !auth.has_key?(:provider) or 
      !auth.has_key?(:uid) or !auth.has_key?(:info) or
      !auth[:info].has_key?(:email) or !auth[:info].has_key?(:name) or 
      auth.uid.length == 0 or auth.provider.length == 0 or
      auth.info.email.length == 0 or auth.info.email.length == 0

      flash[:error] = "Не успяхме да ви оторизираме чрез Google поради невалидни данни"
      return redirect_to new_session_path
    end

    user = User.where(provider: auth.provider, uid: auth.uid).first
    register_user = false

    # first time login with this provider
    unless user
      user = User.where(email: auth.info.email).last
      
      # found user with such email - add provider and uid
      if user
        user.provider = auth.provider
        user.uid = auth.uid
        user.save!

      # first time login with this provider & no user with such email - register user
      else
        user = User.new(skip_from_google_login: true)
        user.provider = auth.provider
        user.uid = auth.uid
        user.email = auth.info.email
        user.password = Devise.friendly_token[0,20] #??? should I fill password field or skip it
        user.name = auth.info.name
        user.login = auth.uid   #??? should I generate some other uniq random string for login
        user.role = User::CONTESTER
        user.save! if user.valid?
        register_user = true
      end

    end

    if !user.nil? and user.persisted?
      self.current_user = user
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"

      if register_user
        flash[:error] = "Данните в профила Ви не са пълни. Моле попълнете липсващите данни."
        redirect_to edit_user_path(self.current_user)
      elsif session[:back]
        back_path = session[:back]
        session[:back] = nil
        redirect_to back_path
      else
        redirect_to root_path
      end

    else
      flash[:error] = "Регистрирайте се, за да използвате системата"
      redirect_to signup_url
    end

  end

  def failure
    flash[:error] = "Не успяхме да ви оторизираме чрез Google"
    redirect_to new_session_path
  end

end