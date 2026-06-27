class Song < ApplicationRecord
  # Association mapping: Artist_id links back to the primary key of the users table
  belongs_to :user, foreign_key: 'artist_id'

  # Validations
  validates :title, presence: true
  validates :mp3_file_path, presence: true

  # Callback: Automatically delete the physical MP3 file from storage when the song is destroyed
  before_destroy :delete_mp3_file

  private

  # Physically deletes the MP3 file from the public/ directory
  def delete_mp3_file
    if mp3_file_path.present?
      path = Rails.root.join('public', mp3_file_path.delete_prefix('/'))
      File.delete(path) if File.exist?(path)
    end
  end
end
