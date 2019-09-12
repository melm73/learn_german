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
      translation = translations_by_word[word.id]

      {
        wordId: word.id,
        german: word.german,
        article: word.article,
        translated: translation.present?,
        sentence: translation&.sentence,
        level: 0,
        timesReviewed: 0,
        lastReview: nil,
        learnt: false,
      }
    end
  end

  def translations_by_word
    @translations_by_word ||= Hash[Translation
      .where(user_id: current_user.id)
      .to_a
      .map { |translation| [translation.word_id, translation] }]
  end
end
