require 'bundler/setup'
Bundler.require

class User < ActiveRecord::Base
    has_secure_password
    validates :name,
        presence: true,
        format: {with: /\A\w+\z/ }
    validates :password,
        length: { in: 5..10 }
end