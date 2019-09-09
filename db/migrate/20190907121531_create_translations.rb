class CreateTranslations < ActiveRecord::Migration[6.0]
  def change
    create_table :translations, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :word_id
      t.string :translation
      t.text :sentence
      t.boolean :known

      t.timestamps
    end

    add_index :translations, [:user_id, :word_id], unique: true
  end
end
