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
    redirect '/'
end

post '/signin' do
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
    end
    redirect '/'
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