class ProgressController < ApplicationController
  def index
    menu_props
    @progress_props = {
      urls: {}
    }

    render :index
  end
end
