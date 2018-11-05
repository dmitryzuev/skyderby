module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def facebook
      if current_user.present? && current_user.registered?
        connect_facebook
      else
        register_facebook
      end
    end

    def failure
      redirect_to root_path
    end

    private

    def connect_facebook
      current_user.add_data_from_facebook(request.env['omniauth.auth'])
      if current_user.save && is_navigational_format?
        set_flash_message(:notice, :success_connect, kind: 'Facebook')
      elsif is_navigational_format?
        set_flash_message(:alert, :failure_connect, kind: 'Facebook')
      end
      redirect_to after_sign_in_path_for(current_user)
    end

    def register_facebook
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
        set_flash_message(:notice, :success, kind: 'Facebook') if is_navigational_format?
      else
        session['devise.facebook_data'] = request.env['omniauth.auth']
        redirect_to new_user_registration_url
      end
    end
  end
end
