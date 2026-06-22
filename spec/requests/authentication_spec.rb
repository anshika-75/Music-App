require 'rails_helper'

RSpec.describe "Authentication and Accounts", type: :request do
  describe "Registration" do
    it "renders the signup page" do
      get new_user_path
      expect(response).to have_http_status(:success)
    end

    it "registers a new artist user and creates their profile" do
      expect {
        post users_path, params: { user: { email: 'newartist@example.com', password: 'password', role: 'artist' } }
      }.to change(User, :count).by(1)
      
      user = User.last
      expect(user.role).to eq('artist')
      expect(user.artist_profile).to be_present
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(songs_path)
    end

    it "registers a new listener user and creates their profile" do
      expect {
        post users_path, params: { user: { email: 'newlistener@example.com', password: 'password', role: 'listener' } }
      }.to change(User, :count).by(1)
      
      user = User.last
      expect(user.role).to eq('listener')
      expect(user.listener_profile).to be_present
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(search_path)
    end
  end

  describe "Login & Logout Session" do
    let!(:user) { User.create!(email: 'user@example.com', password: 'password', role: 'listener') }

    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:success)
    end

    it "logs in a user with valid credentials" do
      post login_path, params: { email: 'user@example.com', password: 'password' }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(search_path)
    end

    it "fails to log in with invalid credentials" do
      post login_path, params: { email: 'user@example.com', password: 'wrong' }
      expect(session[:user_id]).to be_nil
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "logs out a user" do
      post login_path, params: { email: 'user@example.com', password: 'password' }
      expect(session[:user_id]).to eq(user.id)

      delete logout_path
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Account Deletion" do
    let!(:artist) { User.create!(email: 'artist@example.com', password: 'password', role: 'artist') }
    before { artist.create_artist_profile! }

    it "deletes the user and clears session" do
      post login_path, params: { email: 'artist@example.com', password: 'password' }
      
      expect {
        delete user_path(artist)
      }.to change(User, :count).by(-1)
      
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
