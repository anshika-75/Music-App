class Song < ApplicationRecord
  belongs_to :user, foreign_key: 'artist_id'

  validates :title, presence: true
  validates :mp3_file_path, presence: true
end
