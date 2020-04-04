class WordsController < ApplicationController
  before_action :require_login

  def index
    words = Word.all.map do |word|
      serialize_word(word)
    end

    render json: words
  end

  private

  def serialize_word(word)
    {
      id: word.id,
      german: word.german,
      article: word.article,
      category: word.category,
      plural: word.plural,
      duolingoLevel: word.duolingo_level,
      goetheLevel: word.goethe_level,
    }
  end
end
