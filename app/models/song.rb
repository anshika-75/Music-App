class Song < ApplicationRecord
  belongs_to :user, foreign_key: 'artist_id'

  validates :title, presence: true
  validates :mp3_file_path, presence: true

  before_destroy :delete_mp3_file

  private

  def delete_mp3_file
    if mp3_file_path.present?
      path = Rails.root.join('public', mp3_file_path.delete_prefix('/'))
      File.delete(path) if File.exist?(path)
    end
  end
end
