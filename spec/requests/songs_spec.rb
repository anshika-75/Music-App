require 'rails_helper'

RSpec.describe "Songs CRUD", type: :request do
  let!(:artist) { User.create!(email: 'artist@example.com', password: 'password', role: 'artist') }
  let!(:listener) { User.create!(email: 'listener@example.com', password: 'password', role: 'listener') }
  
  before do
    artist.create_artist_profile!(name: 'Artist Bob')
    listener.create_listener_profile!(name: 'Listener Bob')
  end

  describe "Access Control" do
    it "denies access to index for listeners" do
      post login_path, params: { email: 'listener@example.com', password: 'password' }
      get artist_songs_path
      expect(response).to redirect_to(root_path)
    end

    it "allows access to index for artists" do
      post login_path, params: { email: 'artist@example.com', password: 'password' }
      get artist_songs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Song Actions" do
    before do
      # Log in the artist
      post login_path, params: { email: 'artist@example.com', password: 'password' }
    end

    it "creates a new song" do
      dummy_file = fixture_file_upload(Rails.root.join('Gemfile'), 'audio/mpeg') # Use any file, we will stub upload
      allow_any_instance_of(Artist::SongsController).to receive(:upload_mp3).and_return('/uploads/test.mp3')

      expect {
        post artist_songs_path, params: { song: { title: 'New Track', genre: 'Rock', description: 'Cool song', mp3_file: dummy_file } }
      }.to change(Song, :count).by(1)

      expect(response).to redirect_to(artist_songs_path)
      expect(Song.last.title).to eq('New Track')
    end

    context "with existing song" do
      let!(:song) { Song.create!(title: 'Old Song', genre: 'Pop', mp3_file_path: '/uploads/old.mp3', user: artist) }

      it "updates text details without changing MP3" do
        patch artist_song_path(song), params: { song: { title: 'Updated Title', genre: 'Synthpop' } }
        expect(response).to redirect_to(artist_song_path(song))
        
        song.reload
        expect(song.title).to eq('Updated Title')
        expect(song.genre).to eq('Synthpop')
      end

      it "treats as new upload when a new MP3 file is provided" do
        dummy_file = fixture_file_upload(Rails.root.join('Gemfile'), 'audio/mpeg')
        allow_any_instance_of(Artist::SongsController).to receive(:upload_mp3).and_return('/uploads/brand_new.mp3')

        expect {
          patch artist_song_path(song), params: { song: { title: 'Updated Title', mp3_file: dummy_file } }
        }.to change(Song, :count).by(1) # Count increases because it's treated as a new upload!

        expect(response).to redirect_to(artist_songs_path)
      end

      it "deletes a song" do
        # Stub the file deletion callback so it doesn't fail on missing mocked files
        allow_any_instance_of(Song).to receive(:delete_mp3_file).and_return(true)

        expect {
          delete artist_song_path(song)
        }.to change(Song, :count).by(-1)

        expect(response).to redirect_to(artist_songs_path)
      end
    end
  end
end
