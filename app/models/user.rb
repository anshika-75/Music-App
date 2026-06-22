class User < ApplicationRecord
  has_one :artist_profile, dependent: :destroy
  has_one :listener_profile, dependent: :destroy
  has_many :songs, foreign_key: 'artist_id', dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true
  validates :role, presence: true, inclusion: { in: %w[artist listener] }

  # Bcrypt manual password handling since the column name is 'password'
  # instead of the standard 'password_digest' required by has_secure_password.
  def password=(raw_password)
    if raw_password.present?
      self[:password] = BCrypt::Password.create(raw_password)
    end
  end

  # Verifies if the raw password matches the stored bcrypt hash.
  def authenticate(raw_password)
    return false if self[:password].blank?
    BCrypt::Password.new(self[:password]) == raw_password
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
