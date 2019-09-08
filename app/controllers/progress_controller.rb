class ProgressController < ApplicationController
  def index
    menu_props(current_page: 'progress')
    @progress_props = {
      urls: {}
    }

    render :index
  end
end
