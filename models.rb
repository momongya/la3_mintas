require 'bundler/setup'
Bundler.require

class User < ActiveRecord::Base
    has_secure_password
    validates :name,
        uniqueness: { message: "を被りのないものに変更してください" }
    validates :name,
        length: { 
            in: 5..15,
            message: "を5から15文字の長さで入力してください"
        }
    validates :name,
        format: {
            with: /\A\w+\z/,
            message: "を英字で入力してください"
        }
    validates :password,
        format: {
            with: /(?=.*?[a-z])(?=.*?[0-9])/,
            message: "に半角英字と半角数字をそれぞれ1文字以上入れてください"
        },
        length: { 
            in: 5..15,
            message: "を5から15文字の長さで入力してください"
        }
    validates :email,
        format: {
            with: /\A.+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+\z/, 
            message: "を形式にあうものを入力してください"
        }
    
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
    validates :group_name,
        presence: { message: "を入力してください" },
        uniqueness: { message: "を被りのないものに変更してください" }
    validates :code,
        presence: { message: "を入力してください" },
        length: { 
            in: 5..15,
            message: "を5から15文字の長さで入力してください"
        }
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