class WordsController < ApplicationController
  def index
    if logged_in?
      words = Word.all.take(500).map do |word|
        serialize_word(word)
      end

      render json: words
    else
      render json: 'Access Denied', status: :unauthorized
    end
  end

  private

  def serialize_word(word)
    {
      id: word.id,
      german: word.german,
      article: word.article,
      category: word.category,
      plural: word.plural,
      level: word.duolingo_level,
    }
  end
end
