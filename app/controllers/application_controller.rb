class ApplicationController < ActionController::Base
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
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

  def menu_props(current_page:)
    @menu_props = {
      user: { name: current_user.name },
      currentPage: current_page,
      urls: {
        logoutUrl: logout_path,
        currentUserProfileUrl: current_user_profile_users_path,
        wordsUrl: words_path,
        progressUrl: progress_index_path,
        translationsUrl: translations_path,
      },
    }
  end
end
