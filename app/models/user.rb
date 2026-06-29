class User < ApplicationRecord
  # Cascading Deletion: Deleting a user automatically deletes associated profiles and songs
  has_one :artist_profile, dependent: :destroy
  has_one :listener_profile, dependent: :destroy
  has_many :songs, foreign_key: 'artist_id', dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true
  validates :role, presence: true, inclusion: { in: %w[artist listener] }

  # BCrypt manual hashing: Used since the column name is 'password' instead of 'password_digest'
  def password=(raw_password)
    if raw_password.present?
      self[:password] = BCrypt::Password.create(raw_password)
    end
  end

  def authenticate(raw_password)
    return false if self[:password].blank?
    BCrypt::Password.new(self[:password]) == raw_password
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
