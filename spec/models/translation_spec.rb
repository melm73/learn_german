# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Translation, type: :model do
  describe 'validations' do
    it 'is invalid if there is already a translation for a specific user and word' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      Translation.create(user: user, word: word)

      duplicate_translation = Translation.new(user: user, word: word)
      expect(duplicate_translation.valid?).to be_falsey
    end
  end

  describe '#last_reviewed' do
    it 'gets the date of the last review' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word)
      translation.reviews.create!(correct: true, created_at: '2019-01-01')
      translation.reviews.create!(correct: true, created_at: '2019-02-01')

      expect(translation.last_reviewed).to eq('2019-02-01')
    end

    it 'returns nil if there are no reviews' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word)

      expect(translation.last_reviewed).to be_nil
    end
  end

  describe '#review_count' do
    it 'is 0 if there are no reviews' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)

      expect(translation.review_count).to eq(0)
    end

    it 'counts the number of reviews' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)

      expect(translation.review_count).to eq(2)
    end
  end

  describe '#level' do
    it 'defaults to 0' do
      translation = Translation.create

      expect(translation.level).to eq(0)
    end

    it 'is 5 when translation is known' do
      translation = Translation.create(known: true)

      expect(translation.level).to eq(5)
    end

    it 'is adds levels when reviews are correct' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)
      translation.reviews.create!(correct: true)

      expect(translation.level).to eq(1)

      translation.reviews.create!(correct: true)
      expect(translation.level).to eq(2)
    end

    it 'deducts levels when reviews are incorrect' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: false)

      expect(translation.level).to eq(1)

      translation.reviews.create!(correct: false)
      expect(translation.level).to eq(0)
    end

    it 'cannot have a level less than 0' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)
      translation.reviews.create!(correct: false)

      expect(translation.level).to eq(0)
    end

    it 'cannot have a level less greater than 5' do
      word = Word.create(german: 'eins')
      user = User.create(name: 'me')
      translation = Translation.create!(user: user, word: word, known: false)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)
      translation.reviews.create!(correct: true)

      expect(translation.level).to eq(5)
    end
  end
end
