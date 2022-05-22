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
    
    def esc(text)
        Rack::Utils.escape_html(text)
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

error do
    @error = 'エラーが発生しました。 - ' + env['sinatra.error'].name
    erb :error
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
    
    @user = User.create(
        name: esc(params[:name]),
        email: esc(params[:email]),
        password: esc(params[:password]),
        password_confirmation: esc(params[:password_confirmation]),
        top_img: img_url
    )
    if @user.persisted?
        session[:user] = user.id
    end
    
    if @user.save
        redirect '/group/select'
    else
        @error_message = @user.errors.full_messages
        puts @error_message
        erb :sign_up
    end
    
end

post '/signin' do
    user = User.find_by(name: esc(params[:name]))
    if user && user.authenticate(esc(params[:password]))
        session[:user] = user.id
        redirect '/group/select'
    else 
        @error_message = "ユーザーネームかパスワードのいずれかが間違っています"
        erb :index
    end
end

get '/signout' do
    session[:user] = nil
    redirect '/'
end

get '/group/select' do
    if current_user.nil?
        @groups = Group.none
        erb :index
    else
        @groups = current_user.groups
        erb :group_all
    end
end

get '/group/create' do
    if current_user.nil?
        erb :index
    else
        erb :group_create
    end
end

post '/group/create' do
    group = Group.create(
                group_name: esc(params[:group_name]),
                code: SecureRandom.alphanumeric(10),
                color: esc(params[:color])
                )
    GroupUser.create(
                user_id: current_user.id, 
                group_id: group.id
                )
    if group.save
        redirect '/group/select'
    else
        @error_message = group.errors.full_messages
        puts @error_message
        erb :group_create
    end
end

get '/group/join' do
    if current_user.nil?
        erb :index
    else
        erb :group_join
    end
end

post '/group/join' do
    group = Group.find_by(
                group_name: esc(params[:group_name]),
                code: esc(params[:code])
                )
    GroupUser.create(
                user_id: current_user.id, 
                group_id: group.id
                )
    redirect '/group/select'
end

get '/group/:id/home' do
    if current_user.nil?
        erb :index
    elsif current_group.nil?
        erb :group_all
    else
        session[:group] = params[:id]
        if Task.count == 0
            @task = Task.none
        else
            @task = Task.where(group_id: params[:id])
            @task_todo = Task.where(group_id: params[:id],state: "todo")
            @task_doing = Task.where(group_id: params[:id],state: "doing")
            @task_done = Task.where(group_id: params[:id],state: "done")
        end
        
        erb :task_all
    end
end

get '/group/:id/task/create' do
    if current_user.nil?
        erb :index
    elsif current_group.nil?
        erb :group_all
    else
        erb :task_create
    end
end

post '/group/:id/task/create' do
    current_group.tasks.create(
                title: esc(params[:title]),
                todo: esc(params[:todo]),
                priority: esc(params[:priority]),
                state: "todo",
                leader_id: current_user.id
                )
    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/info' do
    if current_user.nil?
        erb :index
    else
        erb :group_info
    end
end

get '/group/:id/edit' do
    if current_user.nil?
        erb :index
    else
        @group = Group.find(params[:id])
        
        erb :group_edit
    end
end

post '/group/:id/edit' do
    group = Group.find(params[:id])
    
    group.group_name = esc(params[:group_name])
    group.code = esc(params[:code])
    group.color = esc(params[:color])
    group.save
    redirect "/group/#{params[:id]}/info"
end

get '/group/:id/task/:task_id/edit' do
    if current_user.nil?
        erb :index
    else
        @task = Task.find(params[:task_id])
        
        erb :task_edit
    end
end

post '/group/:id/task/:task_id/change_status' do
    task = Task.find(params[:task_id])
    
    if task.state == "doing"
        task.state = "done"
        task.save
    elsif task.state == "done"
        task.state = "doing"
        task.save
    elsif task.state == "todo"
        task.state = "doing"
        task.save
    end
    
    redirect "/group/#{params[:id]}/home"
end

post '/group/:id/task/:task_id/change_todostatus' do
    task = Task.find(params[:task_id])
    task.state = "todo"
    task.save
    redirect "/group/#{params[:id]}/home"
end

post '/group/:id/task/:task_id/edit' do
    task = Task.find(params[:task_id])
    
    task.title = esc(params[:title])
    task.todo = esc(params[:todo])
    task.priority = esc(params[:priority])
    task.state = esc(params[:state])
    task.save

    redirect "/group/#{params[:id]}/home"
end

get '/group/:id/task/:task_id/delete' do
    if current_user.nil?
        erb :index
    else
        task = Task.find(params[:task_id])
        task.delete
        redirect "/group/#{params[:id]}/home"
    end
end

get '/group/:id/task/:task_id/join' do
    if current_user.nil?
        erb :index
    else
        JoinTask.create(
                    task_id: params[:task_id],
                    user_id: current_user.id
                    )
        task = Task.find(params[:task_id])
        if task.state == "todo"
            task.state = "doing"
            task.save
        end
        redirect "/group/#{params[:id]}/home"
    end
end

get '/group/:id/task/:task_id/leave' do
    if current_user.nil?
        erb :index
    else
        j_user = JoinTask.find_by(
                    user_id: current_user.id,
                    task_id: params[:task_id]
                    )
        j_user.delete
        users = JoinTask.find_by(task_id: params[:task_id])
        task = Task.find(params[:task_id])
        if users.nil?
            task.state = "todo"
            task.save
        end
        redirect "/group/#{params[:id]}/home"
    end
end