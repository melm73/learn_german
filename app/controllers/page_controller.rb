class PageController < ApplicationController
  def index
    if logged_in?
      @page_props = page_props
      render :index
    else
      redirect_to login_path
    end
  end

  def page_props
    {
      user: { id: current_user.id, name: current_user.name },
      urls: {
        logoutUrl: logout_path,
        currentUserProfileUrl: current_user_profile_users_path,
        wordsUrl: words_path,
        progressUrl: progresses_path,
        translationsUrl: translations_path,
        reviewsUrl: reviews_path,
      },
    }
  end
end
