require 'bundler/setup'
Bundler.require

class User < ActiveRecord::Base
    has_secure_password
    # validates :name,
    #     presence: true,
    #     format: {with: /\A\w+\z/ }
    # validates :password,
    #     length: { in: 5..10 }
    
    has_many :group_users
    has_many :groups, :through => :group_users
    has_many :join_tasks
    has_many :tasks, :through => :join_tasks
end

class GroupUser < ActiveRecord::Base
    belongs_to :user
    belongs_to :group
end

class Group < ActiveRecord::Base
    has_many :group_users
    has_many :users, :through => :group_users, dependent: :destroy
    has_many :tasks
end

class Task < ActiveRecord::Base
    belongs_to :group
    has_many :users, :through => :groups
    has_many :join_tasks
    has_many :join_users, :through => :join_tasks, :source => :user, dependent: :destroy
end

class JoinTask < ActiveRecord::Base
    belongs_to :user
    belongs_to :task
end