class ProgressController < ApplicationController
  def index
    menu_props(current_page: 'progress')
    @progress_props = {
      progresses: generate_progresses,
      urls: {
        editTransactionUrl: translation_path
      }
    }

    render :index
  end

  private

  def generate_progresses
    Word.all.map do |word|
      {
        wordId: word.id,
        german: word.german,
        article: word.article,
        sentence: nil,
        level: 0,
        timesReviewed: 0,
        lastReview: nil,
        learnt: false,
      }
    end
  end
end
