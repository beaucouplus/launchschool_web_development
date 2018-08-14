require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'find'

configure do
  enable :sessions
  set :session_secret, 'secret'
end


set :public_folder, "public"

get "/" do
  "Getting started."
end

get "/data/:file" do
  data_dir = Dir.pwd + "/data"
  files = Dir.entries(data_dir)
  if files.include?(params[:file])
    headers["Content-Type"] = "text/plain"
    File.readlines("data/#{params[:file]}")
  else
    session[:failure] = "#{params[:file]} does not exist."
    redirect "/index"
  end
end

get "/index" do
  data_dir = Dir.pwd + "/data"
  @files = Dir.entries(data_dir).reject { |item| File.directory?(item) }
  erb :index
end
