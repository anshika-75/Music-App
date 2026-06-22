class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :artist?, :listener?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def artist?
    current_user&.role == 'artist'
  end

  def listener?
    current_user&.role == 'listener'
  end

  def require_login!
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page."
      redirect_to login_path
    end
  end

  def require_artist!
    require_login!
    if logged_in? && !artist?
      flash[:alert] = "Only artists can access this page."
      redirect_to root_path
    end
  end

  def require_listener!
    require_login!
    if logged_in? && !listener?
      flash[:alert] = "Only listeners can access this page."
      redirect_to root_path
    end
  end
end
