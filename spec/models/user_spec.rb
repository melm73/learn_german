require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validation' do
    it 'is valid when all fields are present' do
      expect(User.new(name: 'bob', email: 'bob@bob.com', password: 'password').valid?).to be_truthy
    end

    describe 'name' do
      it 'validates presence' do
        expect(User.new(name: '', email: 'bob@bob.com', password: 'password').valid?).to be_falsey
      end
    end

    describe 'email' do
      it 'validates presence' do
        expect(User.new(name: 'bob', email: '', password: 'password').valid?).to be_falsey
      end

      it 'validates format' do
        expect(User.new(name: 'bob', email: 'bob', password: 'password').valid?).to be_falsey
      end

      it 'validates length no more than 255' do
        expect(User.new(name: 'bob', email: "a" * 245 + "@bobby.com", password: 'password').valid?).to be_truthy
        expect(User.new(name: 'bob', email: "a" * 246 + "@bobby.com", password: 'password').valid?).to be_falsey
      end

      it 'validates uniqueness' do
        user = User.new(name: 'bob', email: 'bob@bob.com', password: 'password')
        duplicate_user = user.dup

        user.save

        expect(duplicate_user.valid?).to be_falsey
      end

      it 'should save email as lowercase' do
        user = User.new(name: 'bob', email: 'BOB@BOB.COM', password: 'password')
        user.save

        expect(user.email).to eq('bob@bob.com')
      end
    end

    describe 'password' do
      it 'validates presence' do
        expect(User.new(name: 'bob', email: 'bob@bob.com', password: '').valid?).to be_falsey
      end

      it 'validates minimum length (6)' do
        expect(User.new(name: 'bob', email: 'bob@bob.com', password: '123456').valid?).to be_truthy
        expect(User.new(name: 'bob', email: 'bob@bob.com', password: '12345').valid?).to be_falsey
      end
    end
  end
end
