class Listener::SearchesController < ApplicationController
  before_action :require_listener!

  def index
    @profile = current_user.listener_profile
  end

  def results
    @profile = current_user.listener_profile
    @query = params[:query].to_s.strip

    if @query.present?
      # Caches the search query matches in Redis for 5 minutes to avoid heavy DB joins
      @songs = Rails.cache.fetch("search_result_#{@query.downcase}", expires_in: 5.minutes) do
        Song.joins("LEFT JOIN artist_profiles ON artist_profiles.user_id = songs.artist_id")
            .joins("INNER JOIN users ON users.id = songs.artist_id")
            .where("songs.title ILIKE :q OR artist_profiles.name ILIKE :q OR users.email ILIKE :q", q: "%#{@query}%")
            .select("songs.*, COALESCE(artist_profiles.name, users.email) AS artist_name")
            .to_a
      end
    else
      @songs = []
    end
  end
end
