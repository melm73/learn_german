class ProgressController < ApplicationController
  before_action :require_login

  def index
    progresses = Translation.where(user_id: current_user.id)

    render json: serialize_progresses(progresses)
  end

  private

  def serialize_progresses(progresses)
    progresses.map do |translation|
      {
        wordId: translation.word_id,
        translated: translation.present?,
        sentence: translation&.sentence,
        level: translation&.level || 0,
        timesReviewed: translation&.review_count || 0,
        lastReviewed: format_date(translation&.last_reviewed),
        learnt: translation&.learnt || false,
      }
    end
  end

  def format_date(date)
    return nil unless date
    date.strftime("%d %b, %Y")
  end
end
