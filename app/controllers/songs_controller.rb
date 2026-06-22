class SongsController < ApplicationController
  before_action :require_artist!

  def index
    # Cache the artist's uploaded songs using Redis
    @songs = Rails.cache.fetch("artist_songs_#{current_user.id}", expires_in: 30.minutes) do
      current_user.songs.order(created_at: :desc).to_a
    end
  end

  def show
    @song = current_user.songs.find(params[:id])
  end

  def new
    @song = current_user.songs.build
  end

  def create
    @song = current_user.songs.build(song_params)
    
    mp3_file = params.dig(:song, :mp3_file)
    if mp3_file.blank?
      @song.errors.add(:mp3_file, "is required")
      render :new, status: :unprocessable_entity and return
    end

    uploaded_path = upload_mp3(mp3_file)
    if uploaded_path.nil?
      @song.errors.add(:mp3_file, "must be an MP3 file (.mp3 only)")
      render :new, status: :unprocessable_entity and return
    end

    @song.mp3_file_path = uploaded_path

    if @song.save
      # Clear the cache
      Rails.cache.delete("artist_songs_#{current_user.id}")
      flash[:notice] = "Song uploaded successfully."
      redirect_to songs_path
    else
      # Clean up uploaded file if database save fails
      delete_physical_file(uploaded_path)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @song = current_user.songs.find(params[:id])
  end

  def update
    @song = current_user.songs.find(params[:id])
    mp3_file = params.dig(:song, :mp3_file)

    if mp3_file.present?
      # If MP3 changes: Treat as new upload
      @new_song = current_user.songs.build(
        title: params.dig(:song, :title).presence || @song.title,
        genre: params.dig(:song, :genre).presence || @song.genre,
        description: params.dig(:song, :description).presence || @song.description
      )
      uploaded_path = upload_mp3(mp3_file)
      if uploaded_path
        @new_song.mp3_file_path = uploaded_path
        if @new_song.save
          Rails.cache.delete("artist_songs_#{current_user.id}")
          flash[:notice] = "New song uploaded successfully (treated as new upload because MP3 changed)."
          redirect_to songs_path and return
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
      # Standard text fields update
      if @song.update(song_params)
        Rails.cache.delete("artist_songs_#{current_user.id}")
        flash[:notice] = "Song details updated successfully."
        redirect_to song_path(@song)
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @song = current_user.songs.find(params[:id])
    
    # Active Record destroy callback will automatically trigger local file deletion
    if @song.destroy
      Rails.cache.delete("artist_songs_#{current_user.id}")
      flash[:notice] = "Song deleted successfully."
    else
      flash[:alert] = "Could not delete song."
    end
    
    redirect_to songs_path
  end

  private

  def song_params
    params.require(:song).permit(:title, :genre, :description)
  end

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

  def delete_physical_file(relative_path)
    if relative_path.present?
      path = Rails.root.join('public', relative_path.delete_prefix('/'))
      File.delete(path) if File.exist?(path)
    end
  end
end
