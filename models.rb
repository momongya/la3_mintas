require 'bundler/setup'
Bundler.require

class User < ActiveRecord::Base
    has_secure_password
    validates :name,
        presence: true,
        format: {with: /\A\w+\z/ }
    validates :password,
        length: { in: 5..10 }
    
    has_many :group_users
    has_many :groups, :through => :group_users
end

class GroupUser < ActiveRecord::Base
    belongs_to :user
    belongs_to :group
end

class Group < ActiveRecord::Base
    has_many :group_users
    has_many :users, :through => :group_users
    has_many :tasks
end

class Task < ActiveRecord::Base
    belongs_to :group
    has_many :users, :through => :groups
end
