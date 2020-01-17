class PageController < ApplicationController
  def index
    if logged_in?
      @page_props = menu_props(current_page: 'progress')
      render :index
    else
      redirect_to login_path
    end
  end
end
