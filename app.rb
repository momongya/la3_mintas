require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'dotenv/load'
require 'open-uri'
require 'json'
require 'net/http'
require 'sinatra/activerecord'
require 'securerandom'

enable :sessions

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
    
    def current_group
        Group.find_by(id: session[:group])
    end
end

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
end

get '/' do
    erb :index
end

get '/signup' do
    erb :sign_up
end

post '/signup' do
    img = params[:top_img]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
    
    user = User.create(
        name: params[:name],
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        top_img: img_url
    )
    if user.persisted?
        session[:user] = user.id
    end
    redirect '/group/select'
end

post '/signin' do
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
    end
    redirect '/group/select'
end

get '/signout' do
    session[:user] = nil
    redirect '/'
end

get '/group/select' do
    if current_user.nil?
        @groups = Group.none
    else
        @groups = current_user.groups
    end
    erb :group_all
end

get '/group/create' do
    erb :group_create
end

post '/group/create' do
    group = Group.create(group_name: params[:group_name],code: SecureRandom.alphanumeric(10),color: params[:color])
    GroupUser.create(user_id: current_user.id, group_id: group.id)
    
    redirect '/group/select'
end

get '/group/join' do
    erb :group_join
end

post '/group/join' do
    group = Group.find_by(group_name: params[:group_name],code: params[:code])
    GroupUser.create(user_id: current_user.id, group_id: group.id)
    
    redirect '/group/select'
end

get '/group/:id/home' do
    session[:group] = params[:id]
    if Task.count == 0
        @task = Task.none
    else
        @task = Task.where(group_id: params[:id])
    end
    
    erb :task_all
end

get '/group/:id/task/create' do
    erb :task_create
end

post '/group/:id/task/create' do
    current_group.tasks.create(
                title: params[:title],
                todo: params[:todo],
                priority: params[:priority],
                state: "todo",
                leader_id: current_user.id
                )
    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/info' do
    erb :group_info
end

get '/group/:id/edit' do
    @group = Group.find(params[:id])
    
    erb :group_edit
end

post '/group/:id/edit' do
    group = Group.find(params[:id])
    
    group.group_name = params[:group_name]
    group.code = params[:code]
    group.color = params[:color]
    group.save
    redirect "/group/#{params[:id]}/info"
end

get '/group/:id/task/:task_id/edit' do
    @task = Task.find(params[:task_id])
    
    erb :task_edit
end

post '/group/:id/task/:task_id/edit' do
    task = Task.find(params[:task_id])
    
    task.title = params[:title]
    task.todo = params[:todo]
    task.priority = params[:priority]
    task.state = params[:state]
    task.save

    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/task/:task_id/delete' do
    task = Task.find(params[:task_id])
    task.delete
    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/task/:task_id/join' do
    JoinTask.create(
                task_id: params[:task_id],
                user_id: current_user.id
                )
    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/task/:task_id/leave' do
    j_user = JoinTask.find_by(user_id: current_user.id,task_id: params[:task_id])
    j_user.delete
    redirect "/group/#{params[:id]}/home"
end