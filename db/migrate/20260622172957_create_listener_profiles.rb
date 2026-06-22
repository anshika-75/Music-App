class CreateListenerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :listener_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :profile_photo

      t.timestamps
    end
  end
end
