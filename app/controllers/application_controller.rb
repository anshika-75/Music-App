class ApplicationController < ActionController::Base
  # Restrict access to modern browser configurations
  allow_browser versions: :modern

  # Optimize client-side caching of resources
  stale_when_importmap_changes

  # Expose helper methods to view templates (.html.erb)
  helper_method :current_user, :logged_in?, :artist?, :listener?

  private

  # Retrieves the current user from the session cookie, if one exists
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Returns true if a user is logged in
  def logged_in?
    current_user.present?
  end

  # Helper to identify if the logged in user is an artist
  def artist?
    current_user&.role == 'artist'
  end

  # Helper to identify if the logged in user is a listener
  def listener?
    current_user&.role == 'listener'
  end

  # Authorization filter: Redirects to login page if user is not authenticated
  def require_login!
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page."
      redirect_to login_path
    end
  end

  # Authorization filter: Redirects to root dashboard if user is not an artist
  def require_artist!
    require_login!
    if logged_in? && !artist?
      flash[:alert] = "Only artists can access this page."
      redirect_to root_path
    end
  end

  # Authorization filter: Redirects to root dashboard if user is not a listener
  def require_listener!
    require_login!
    if logged_in? && !listener?
      flash[:alert] = "Only listeners can access this page."
      redirect_to root_path
    end
  end
end
