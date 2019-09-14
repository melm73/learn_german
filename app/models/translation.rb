class Translation < ApplicationRecord
  # translation: string
  # sentence: string
  # known: boolean

  MIN_LEVEL = 0
  MAX_LEVEL = 5

  belongs_to :user
  belongs_to :word
  has_many :reviews

  validates :user_id, uniqueness: { scope: :word_id, message: 'should only have one translation per word' }

  def level
    return MAX_LEVEL if known

    level = MIN_LEVEL
    reviews.each do |review|
      if review.correct
        level += 1 unless level == MAX_LEVEL
      else
        level -= 1 unless level == MIN_LEVEL
      end
    end
    level
  end

  def last_reviewed
    reviews.last&.created_at
  end

  def review_count
    reviews.count || 0
  end

  def learnt
    known || (level == MAX_LEVEL)
  end
end
