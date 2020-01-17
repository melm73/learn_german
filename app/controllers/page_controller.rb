class PageController < ApplicationController
  def index
    @page_props = {
      urls: {
      },
    }
    render :index
  end
end
