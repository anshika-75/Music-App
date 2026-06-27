class Artist::ProfilesController < ApplicationController
  before_action :require_artist!

  def edit
    @profile = current_user.artist_profile
  end

  def update
    @profile = current_user.artist_profile
    
    # Extract user and profile parameters
    up_params = params.require(:artist_profile).permit(:email, :password)
    profile_params = params.require(:artist_profile).permit(:name, :bio)

    # Assign values to current_user
    current_user.email = up_params[:email] if up_params[:email].present?
    
    # Only assign password if it is provided (avoid blanking it out)
    if up_params[:password].present?
      current_user.password = up_params[:password]
    end

    # Validate both objects. Save if both are valid.
    if current_user.valid? && @profile.update(profile_params)
      current_user.save
      flash[:notice] = "Profile updated successfully."
      redirect_to artist_songs_path
    else
      # Merge user validation errors into profile errors so they display on the form
      current_user.errors.each do |error|
        @profile.errors.add(error.attribute, error.message)
      end
      flash.now[:alert] = "Could not update profile."
      render :edit, status: :unprocessable_entity
    end
  end
end
