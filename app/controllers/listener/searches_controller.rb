class Listener::SearchesController < ApplicationController
  # Require listener authentication for search actions
  before_action :require_listener!

  # GET /listener/search - Renders search dashboard
  def index
    @profile = current_user.listener_profile
  end

  # GET /listener/search/results - Queries tracks and returns results
  def results
    @profile = current_user.listener_profile
    @query = params[:query].to_s.strip

    if @query.present?
      # Redis Caching: Caches search matches by query key for 5 minutes
      @songs = Rails.cache.fetch("search_result_#{@query.downcase}", expires_in: 5.minutes) do
        # PostgreSQL Query: Performs join and case-insensitive pattern matching on Title, Artist Name, or Email
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
