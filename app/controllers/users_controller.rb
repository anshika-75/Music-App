class UsersController < ApplicationController
  before_action :require_login!, only: [:destroy]

  def new
    if logged_in?
      redirect_to_dashboard
    else
      @user = User.new
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      if @user.role == 'artist'
        @user.create_artist_profile!
      elsif @user.role == 'listener'
        @user.create_listener_profile!
      end
      session[:user_id] = @user.id
      flash[:notice] = "Account created successfully."
      redirect_to_dashboard
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Active Record's dependent: :destroy associations on the User model
    # will trigger the destroy callbacks on ArtistProfile, ListenerProfile, and Songs.
    # We will implement the physical file deletion in model before_destroy callbacks.
    current_user.destroy
    session[:user_id] = nil
    flash[:notice] = "Your account has been successfully deleted."
    redirect_to root_path
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :role)
  end

  def redirect_to_dashboard
    if artist?
      redirect_to artist_songs_path
    elsif listener?
      redirect_to listener_search_path
    else
      redirect_to root_path
    end
  end
end
