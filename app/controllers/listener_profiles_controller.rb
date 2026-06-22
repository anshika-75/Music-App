class ListenerProfilesController < ApplicationController
  before_action :require_listener!

  def edit
    @profile = current_user.listener_profile
  end

  def update
    @profile = current_user.listener_profile
    
    # Extract params
    up_params = params.require(:listener_profile).permit(:email, :password)
    profile_params = params.require(:listener_profile).permit(:name)
    photo_file = params.dig(:listener_profile, :profile_photo)

    # Assign user values
    current_user.email = up_params[:email] if up_params[:email].present?
    if up_params[:password].present?
      current_user.password = up_params[:password]
    end

    # Handle local profile photo upload if provided
    if photo_file.present?
      uploaded_path = upload_photo(photo_file)
      if uploaded_path
        # Delete old photo if it exists
        if @profile.profile_photo.present?
          old_path = Rails.root.join('public', @profile.profile_photo.delete_prefix('/'))
          File.delete(old_path) if File.exist?(old_path)
        end
        @profile.profile_photo = uploaded_path
      else
        @profile.errors.add(:profile_photo, "must be an image file (.jpg, .jpeg, .png, .gif)")
      end
    end

    # Save only if there are no errors on profile and user is valid
    if @profile.errors.empty? && current_user.valid? && @profile.update(profile_params)
      current_user.save
      flash[:notice] = "Profile updated successfully."
      redirect_to search_path
    else
      current_user.errors.each do |error|
        @profile.errors.add(error.attribute, error.message)
      end
      flash.now[:alert] = "Could not update profile."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def upload_photo(uploaded_io)
    extension = File.extname(uploaded_io.original_filename).downcase
    return nil unless %w[.jpg .jpeg .png .gif].include?(extension)

    directory = Rails.root.join('public', 'uploads', 'profiles')
    FileUtils.mkdir_p(directory) unless File.exist?(directory)

    filename = "#{SecureRandom.uuid}#{extension}"
    path = directory.join(filename)

    File.open(path, 'wb') do |file|
      file.write(uploaded_io.read)
    end

    "/uploads/profiles/#{filename}"
  end
end
