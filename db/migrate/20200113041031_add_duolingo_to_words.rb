class AddDuolingoToWords < ActiveRecord::Migration[6.0]
  def change
    add_column :words, :duolingo_level, :integer
  end
end
