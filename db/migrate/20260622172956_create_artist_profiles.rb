class CreateArtistProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :artist_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :bio

      t.timestamps
    end
  end
end
