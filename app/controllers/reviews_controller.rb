class ReviewsController < ApplicationController
  def index
    if logged_in?
      menu_props(current_page: 'review')
      @review_page_props = {
        urls: {
        },
      }

      render :index
    else
      redirect_to login_path
    end
  end

  def create
    translation_id = params[:translation_id]
    review = Review.create(translation_id: translation_id, correct: params[:correct])
    render json: review
  end
end
