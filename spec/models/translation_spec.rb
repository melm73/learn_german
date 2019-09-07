require 'rails_helper'

RSpec.describe Translation, type: :model do
  describe 'validations' do
    it 'is invalid if there is already a translation for a specific user and word'do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create(user: user, word: word)

      duplicate_translation = Translation.new(user: user, word: word)
      expect(duplicate_translation.valid?).to be_falsey
    end
  end
end
