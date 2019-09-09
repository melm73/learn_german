class TranslationsController < ApplicationController
  def edit
    translation = Translation.find_by(user_id: current_user.id, word_id: word_id)

    menu_props(current_page: 'translation')
    @translation_props = {
      word: serialize_word,
      translation: serialize_translation(translation),
      urls: {}
    }

    render :edit
  end

  private

  def word_id
    @word_id ||= params.permit(:word_id)[:word_id]
  end

  def serialize_translation(translation)
    return unless translation
      
    {
      id: translation.id,
      user_id: translation.user_id,
      word_id: translation.word_id,
      translation: translation.translation,
      sentence: translation.sentence,
      known: translation.known,
    }
  end

  def serialize_word
    word = Word.find(word_id)

    {
      id: word.id,
      german: word.german,
      article: word.article,
    }
  end
end
