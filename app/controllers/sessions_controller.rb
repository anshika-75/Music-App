class SessionsController < ApplicationController
  def new
    if logged_in?
      redirect_to_dashboard
    end
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:email].to_s.strip.downcase)
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Logged in successfully."
      redirect_to_dashboard
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Logged out successfully."
    redirect_to root_path
  end

  private

  def redirect_to_dashboard
    if artist?
      redirect_to songs_path
    elsif listener?
      redirect_to search_path
    else
      redirect_to root_path
    end
  end
end
