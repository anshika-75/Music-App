require 'rails_helper'

RSpec.describe Song, type: :model do
  let(:user) { User.create!(email: 'singer@example.com', password: 'password', role: 'artist') }

  describe 'validations' do
    it 'is valid with a title, mp3_file_path, and artist (user)' do
      song = Song.new(
        title: 'Imagine',
        mp3_file_path: '/uploads/imagine.mp3',
        user: user
      )
      expect(song).to be_valid
    end

    it 'is invalid without a title' do
      song = Song.new(title: nil, mp3_file_path: '/uploads/song.mp3', user: user)
      song.valid?
      expect(song.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without an mp3_file_path' do
      song = Song.new(title: 'Imagine', mp3_file_path: nil, user: user)
      song.valid?
      expect(song.errors[:mp3_file_path]).to include("can't be blank")
    end
  end
end
