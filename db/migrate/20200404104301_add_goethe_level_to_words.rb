class AddGoetheLevelToWords < ActiveRecord::Migration[6.0]
  def change
    add_column :words, :goethe_level, :string
  end
end
