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


# sqlite3
# create table "users" (
#   "id" char(36) default (lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || substr(lower(hex(randomblob(2))),2) || '-' || substr('89ab',abs(random()) % 4 + 1, 1) || substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(6)))), 
#   "name" varchar(255), "email" varchar, "password_digest" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, primary key ("id")
# );
