class AddChapterToWords < ActiveRecord::Migration[6.0]
  def change
    add_column :words, :chapter, :string
  end
end
