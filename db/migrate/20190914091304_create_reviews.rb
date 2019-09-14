class CreateReviews < ActiveRecord::Migration[6.0]
  def change
    create_table :reviews, id: :uuid do |t|
      t.boolean :correct
      t.uuid :translation_id

      t.timestamps
    end

    add_foreign_key :reviews, :translations
  end
end
