require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with email, password, and role' do
      user = User.new(
        email: 'artist@example.com',
        password: 'password123',
        role: 'artist'
      )
      expect(user).to be_valid
    end

    it 'is invalid without an email' do
      user = User.new(email: nil)
      user.valid?
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid with a duplicate email' do
      User.create!(email: 'duplicate@example.com', password: 'password123', role: 'listener')
      user = User.new(email: 'duplicate@example.com', password: 'password456', role: 'artist')
      user.valid?
      expect(user.errors[:email]).to include("has already been taken")
    end

    it 'is invalid without a password' do
      user = User.new(password: nil)
      user.valid?
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'is invalid with an incorrect role' do
      user = User.new(role: 'admin')
      user.valid?
      expect(user.errors[:role]).to include("is not included in the list")
    end
  end

  describe 'password hashing' do
    it 'hashes the password using bcrypt' do
      user = User.new(password: 'secret123')
      expect(user.password).not_to eq('secret123')
      expect(user.authenticate('secret123')).to be true
      expect(user.authenticate('wrong')).to be false
    end
  end
end
