require 'rails_helper'

RSpec.describe "Search System", type: :request do
  let!(:artist) { User.create!(email: 'artist@example.com', password: 'password', role: 'artist') }
  let!(:listener) { User.create!(email: 'listener@example.com', password: 'password', role: 'listener') }
  
  before do
    artist.create_artist_profile!(name: 'The Beatles')
    listener.create_listener_profile!(name: 'Listener Bob')
    Song.create!(title: 'Yellow Submarine', genre: 'Rock', mp3_file_path: '/uploads/yellow.mp3', user: artist)
  end

  describe "Access Control" do
    it "denies search access to artists" do
      post login_path, params: { email: 'artist@example.com', password: 'password' }
      get search_path
      expect(response).to redirect_to(root_path)
    end

    it "allows search access to listeners" do
      post login_path, params: { email: 'listener@example.com', password: 'password' }
      get search_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Perform Search" do
    before do
      post login_path, params: { email: 'listener@example.com', password: 'password' }
    end

    it "finds song by title" do
      get search_results_path, params: { query: 'Submarine' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Yellow Submarine')
      expect(response.body).to include('The Beatles')
    end

    it "finds song by artist name" do
      get search_results_path, params: { query: 'Beatles' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Yellow Submarine')
    end

    it "renders empty state on no match" do
      get search_results_path, params: { query: 'NonExistentSong' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('No songs found')
    end
  end
end
