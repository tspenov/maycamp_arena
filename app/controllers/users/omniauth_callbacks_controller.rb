class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def google_oauth2

    auth = request.env["omniauth.auth"]

    if invalid_omniauth_params?(auth)
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
        user.update(provider: auth.provider, uid: auth.uid)
      # first time login with this provider & no user with such email - register user
      else
        user = register_user_from_omniath(auth)
        register_user = true
      end
    end

    if !user.nil? and user.persisted?
      self.current_user = user
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"

      if register_user
        flash[:error] = "Данните в профила Ви не са пълни. Моле попълнете липсващите данни."
        redirect_to edit_user_path(self.current_user)
      else
        redirect_back_or(root_path)
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

  private

    def invalid_omniauth_params?(auth)
      !auth || auth.provider.blank? || auth.uid.blank? || auth.info.blank? ||
       auth.info.name.blank? || auth.info.email.blank?
    end

    def register_user_from_omniath(auth)
      user = User.new(skip_from_google_login: true)
      user.update(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        password: Devise.friendly_token[0,20],
        name: auth.info.name,
        login: auth.uid,
        role: User::CONTESTER
      )
      return user
    end

    def redirect_back_or(default_path)
      if session[:back]
        back_path = session[:back]
        session[:back] = nil
        redirect_to back_path
      else
        redirect_to default_path
      end
    end

end