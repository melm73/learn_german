class ReviewsController < ApplicationController
  def index
    number_of_translations = 10

    translations = Translation
      .where(user_id: current_user.id).to_a
      .reject(&:learnt)
      .sample(number_of_translations)

    reviews = translations.map do |translation|
      {
        translation: serialize_translation(translation),
        word: serialize_word(translation.word_id),
      }
    end

    render json: reviews
  end

  def create
    translation_id = params[:translation_id]
    review = Review.create(translation_id: translation_id, correct: params[:correct])
    render json: review
  end

  private

  def serialize_translation(translation)
    {
      id: translation.id,
      user_id: translation.user_id,
      translation: translation.translation,
      sentence: translation.sentence,
    }
  end

  def serialize_word(word_id)
    word = Word.find(word_id)

    {
      id: word.id,
      german: word.german,
      article: word.article,
      category: word.category,
    }
  end
end
