class User < ActiveRecord::Base
  devise :two_factor_authenticatable

  devise :registerable, :recoverable, :rememberable,
         :trackable, :validatable
end
