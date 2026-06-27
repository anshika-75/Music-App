class Artist::SongsController < ApplicationController
  # Require artist authentication for all actions
  before_action :require_artist!

  # GET /artist/songs - Display artist dashboard
  def index
    # Redis Caching: Reads from or writes to cache under a user-specific key
    @songs = Rails.cache.fetch("artist_songs_#{current_user.id}", expires_in: 30.minutes) do
      current_user.songs.order(created_at: :desc).to_a
    end
  end

  # GET /artist/songs/:id - Display details of a specific song
  def show
    @song = current_user.songs.find(params[:id])
  end

  # GET /artist/songs/new - Display new song upload form
  def new
    @song = current_user.songs.build
  end

  # POST /artist/songs - Upload and create a new song
  def create
    @song = current_user.songs.build(song_params)
    
    mp3_file = params.dig(:song, :mp3_file)
    if mp3_file.blank?
      @song.errors.add(:mp3_file, "is required")
      render :new, status: :unprocessable_entity and return
    end

    # Handle storage upload
    uploaded_path = upload_mp3(mp3_file)
    if uploaded_path.nil?
      @song.errors.add(:mp3_file, "must be an MP3 file (.mp3 only)")
      render :new, status: :unprocessable_entity and return
    end

    @song.mp3_file_path = uploaded_path

    if @song.save
      # Cache Busting: Remove cached songs list in Redis
      Rails.cache.delete("artist_songs_#{current_user.id}")
      flash[:notice] = "Song uploaded successfully."
      redirect_to artist_songs_path
    else
      # Cleanup: Delete uploaded physical file if SQL insert fails
      delete_physical_file(uploaded_path)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /artist/songs/:id/edit - Display edit metadata form
  def edit
    @song = current_user.songs.find(params[:id])
  end

  # PATCH /artist/songs/:id - Update song details
  def update
    @song = current_user.songs.find(params[:id])
    mp3_file = params.dig(:song, :mp3_file)

    if mp3_file.present?
      # Replacement Rule: If the MP3 file is modified, compile as a new song record
      @new_song = current_user.songs.build(
        title: params.dig(:song, :title).presence || @song.title,
        genre: params.dig(:song, :genre).presence || @song.genre,
        description: params.dig(:song, :description).presence || @song.description
      )
      uploaded_path = upload_mp3(mp3_file)
      if uploaded_path
        @new_song.mp3_file_path = uploaded_path
        if @new_song.save
          # Cache Busting: Clear cached list in Redis
          Rails.cache.delete("artist_songs_#{current_user.id}")
          flash[:notice] = "New song uploaded successfully (treated as new upload because MP3 changed)."
          redirect_to artist_songs_path and return
        else
          delete_physical_file(uploaded_path)
          @song.errors.merge!(@new_song.errors)
          render :edit, status: :unprocessable_entity and return
        end
      else
        @song.errors.add(:mp3_file, "must be an MP3 file (.mp3 only)")
        render :edit, status: :unprocessable_entity and return
      end
    else
      # Standard Metadata Update: update database table record directly
      if @song.update(song_params)
        # Cache Busting: Clear cache
        Rails.cache.delete("artist_songs_#{current_user.id}")
        flash[:notice] = "Song details updated successfully."
        redirect_to artist_song_path(@song)
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  # DELETE /artist/songs/:id - Delete a song
  def destroy
    @song = current_user.songs.find(params[:id])
    
    # ActiveRecord destroy callback automatically invokes before_destroy file cleanup
    if @song.destroy
      # Cache Busting: Clear cache
      Rails.cache.delete("artist_songs_#{current_user.id}")
      flash[:notice] = "Song deleted successfully."
    else
      flash[:alert] = "Could not delete song."
    end
    
    redirect_to artist_songs_path
  end

  private

  # Strong Parameters filtering
  def song_params
    params.require(:song).permit(:title, :genre, :description)
  end

  # Helper: Upload audio track to /public/uploads
  def upload_mp3(uploaded_io)
    extension = File.extname(uploaded_io.original_filename).downcase
    return nil unless extension == '.mp3'

    directory = Rails.root.join('public', 'uploads')
    FileUtils.mkdir_p(directory) unless File.exist?(directory)

    filename = "#{SecureRandom.uuid}#{extension}"
    path = directory.join(filename)

    File.open(path, 'wb') do |file|
      file.write(uploaded_io.read)
    end

    "/uploads/#{filename}"
  end

  # Helper: Delete physical audio track from filesystem
  def delete_physical_file(relative_path)
    if relative_path.present?
      path = Rails.root.join('public', relative_path.delete_prefix('/'))
      File.delete(path) if File.exist?(path)
    end
  end
end
