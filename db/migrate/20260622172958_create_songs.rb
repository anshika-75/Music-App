class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.integer :artist_id, null: false
      t.string :title, null: false
      t.string :genre
      t.text :description
      t.string :mp3_file_path, null: false

      t.timestamps
    end
    add_index :songs, :artist_id
    add_foreign_key :songs, :users, column: :artist_id
  end
end
