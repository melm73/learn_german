class CreateWords < ActiveRecord::Migration[6.0]
  def change
    create_table :words, id: :uuid do |t|
      t.string :article
      t.string :german
      t.string :plural
      t.string :category

      t.timestamps
    end
  end
end
