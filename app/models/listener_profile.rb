class ListenerProfile < ApplicationRecord
  belongs_to :user

  before_destroy :delete_profile_photo

  private

  def delete_profile_photo
    if profile_photo.present?
      path = Rails.root.join('public', profile_photo.delete_prefix('/'))
      File.delete(path) if File.exist?(path)
    end
  end
end
