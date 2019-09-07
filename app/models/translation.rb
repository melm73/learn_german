class Translation < ApplicationRecord
  # translation: string
  # sentence: string
  # known: boolean

  belongs_to :user
  belongs_to :word

  validates :user_id, uniqueness: { scope: :word_id, message: "should only have one translation per word" }
end
