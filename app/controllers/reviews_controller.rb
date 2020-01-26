class ReviewsController < ApplicationController
  before_action :require_login

  def index
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

  def translations
    translation_query = Translation
      .where(user_id: current_user.id).to_a
      .reject(&:learnt)
      .select {|t| level ? t.word.duolingo_level == level : true }
      .sample(number_of_translations) 
  end

  def level
    @level ||= query_params[:level]&.to_i
  end

  def number_of_translations
    @number_of_translations ||= query_params[:count].to_i
  end

  def query_params
    @query_params ||= params.permit(:count, :level)
  end

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
