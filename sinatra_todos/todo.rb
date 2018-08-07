require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  # session[:lists] << { name: "New list", todos: [] }
  # redirect "/lists"
  erb :new_list, layout: :layout
end

post "/lists" do
  list_name = params[:list_name].strip
  if (1..100).cover?(list_name.size)
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  else
    session[:error] = "The list name must be between 1 and 100 characters"
    erb :new_list, layout: :layout
  end
end