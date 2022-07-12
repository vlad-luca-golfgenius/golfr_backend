# ORM class for user model
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :scores, dependent: :destroy

  def serialize
    {
      id: id,
      name: name,
      email: email,
    }
  end
end
