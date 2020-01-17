class PageController < ApplicationController
  def index
    @page_props = menu_props(current_page: 'progress')
    render :index
  end
end
