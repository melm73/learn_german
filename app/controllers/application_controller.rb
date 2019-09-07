class ApplicationController < ActionController::Base

  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  def log_in(user)
    session[:user_id] = user.id
  end

  def logged_in?
    !current_user.nil?
  end

  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  def menu_props
    @menu_props = {
        user: { name: current_user.name },
        urls: { logoutUrl: logout_path }
    }
  end
end
