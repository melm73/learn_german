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
      serialize_progress(word, translation)
    end
  end

  def serialize_progress(word, translation)
    {
      wordId: word.id,
      german: word.german,
      article: word.article,
      chapter: word.chapter,
      translated: translation.present?,
      sentence: translation&.sentence,
      level: translation&.level || 0,
      timesReviewed: translation&.review_count || 0,
      lastReviewed: translation&.last_reviewed,
      learnt: translation&.learnt || false
    }
  end

  def translations_by_word
    @translations_by_word ||=
      Hash[Translation
      .where(user_id: current_user.id)
      .to_a
      .map { |translation| [translation.word_id, translation] }
    ]
  end
end
