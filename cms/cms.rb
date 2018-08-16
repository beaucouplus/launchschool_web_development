require 'find'
require 'pry'
require 'redcarpet'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end


helpers do
  def markdown(string)
    headers["Content-Type"] = "text/html;charset=utf-8"
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(string)
  end

end

def display_raw_content(file)
  File.readlines("data/#{file}").join
end

def display_content(file)
  raw_content = display_raw_content(file)
  if File.extname(file) == ".md"
    @content = markdown(raw_content)
    erb :content
  else
    headers["Content-Type"] = "text/plain"
    if session[:success]
      session.delete(:success) + "\n\n" + File.readlines("data/#{file}").join("\n")
    else
      File.readlines("data/#{file}")
    end
  end
end

set :public_folder, "public"

get "/" do
  "Getting started."
end

get "/data/:file" do
  file = params[:file]
  data_dir = Dir.pwd + "/data"
  files = Dir.entries(data_dir)
  if files.include?(file)
    display_content(file)
  else
    session[:failure] = "#{params[:file]} does not exist."
    redirect "/index"
  end
end

get "/data/:file/edit" do
  @file = params[:file]
  @content = display_raw_content(@file)
  erb :edit
end

post "/data/:file" do
  content = params[:content]
  file = params[:file]
  data_dir = Dir.pwd + "/data/"
  File.open("#{data_dir}#{file}", 'w') { |f| f.write(content) }
  session[:success] = "#{file} has been successfully updated"
  redirect "/data/#{file}"
end

get "/index" do
  data_dir = Dir.pwd + "/data"
  @files = Dir.entries(data_dir).reject { |item| File.directory?(item) }
  erb :index
end
