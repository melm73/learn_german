class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    create_table :users, id: :uuid do |t|
      t.string :name
      t.string :email
      t.string :password_digest

      t.timestamps
    end
    
    add_index :users, :email, unique: true
  end
end
