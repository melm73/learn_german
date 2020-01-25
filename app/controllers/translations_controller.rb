class TranslationsController < ApplicationController
  before_action :require_login

  def index
    translation = Translation.find_by(user_id: current_user.id, word_id: word_id)

    if translation
      render json: [serialize_translation(translation)]
    else
      render json: []
    end
  end

  def create
    translation = Translation.new(translation_params)

    if translation.save
      render json: { id: translation.id }, status: :created
    else
      render json: translation.errors, status: :unprocessable_entity
    end
  end

  def update
    translation = Translation.find(params[:id])
    translation.update(translation_params)

    if translation.save
      render json: {}, status: :ok
    else
      render json: translation.errors, status: :unprocessable_entity
    end
  end

  private

  def translation_params
    params.require(:translation).permit(:user_id, :word_id, :translation, :sentence, :known)
  end

  def word_id
    @word_id ||= params.permit(:word_id)[:word_id]
  end

  def serialize_translation(translation)
    {
      id: translation.id,
      wordId: translation.word_id,
      translation: translation.translation,
      sentence: translation.sentence,
      known: translation.known,
    }
  end
end
