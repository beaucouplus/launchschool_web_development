require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
  session[:list_counter] ||= 0
end


helpers do
  def checkable(list)
    "complete" if list_complete?(list)
  end

  def list_complete?(list)
    list[:todos].size > 0 && remaining(list) == 0
  end

  def remaining(list)
    list[:todos].count { |todo| todo[:completed] == false }
  end

  def sort(lists)
    lists.sort_by { |list| list_complete?(list) ? 1 : 0 }
  end

  def sort_tasks(tasks)
    tasks.sort_by { |task| task[:completed] == true ? 1 : 0 }
  end
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "The list name must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique"
  end
end

def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo must be between 1 and 100 characters"
  end
end

post "/lists" do
  session[:list_counter] += 1
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { id: session[:list_counter], name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  puts @list
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  erb :edit_list, layout: :layout
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been successfully updated"
    redirect "/lists/#{params[:id]}"
  end
end

post "/lists/:id/destroy" do
  idx = session[:lists].index { |list| list[:id] == params[:id].to_i }
  session[:lists].delete_at(idx)
  session[:success] = "The list has been successfully deleted"
  redirect "/lists"
end

post "/lists/:id/todos" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  todos_size = @list[:todos].size
  todo = params[:todo].strip
  error = error_for_todo(todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    todo_id = todos_size + 1
    @list[:todos] << { id: todo_id, name: todo, completed: false }
    session[:success] = "The todo has been created"
    redirect "/lists/#{params[:id] }"
  end
end

post "/lists/:id/todos/:todo_id/destroy" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  @todo = params[:todo_id].to_i
  @list[:todos].delete_at(@todo)
  session[:success] = "The todo has been successfully deleted"
  redirect "/lists/#{params[:id]}"
end

post "/lists/:id/todos/:todo_id" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  @todo = @list[:todos].find { |todo| todo[:id] == params[:todo_id].to_i }
  puts "--- liste ---"
  puts @list
  puts "---- todo"
  puts @todo
  puts "=================="
  is_completed = params[:completed] == "true"
  @todo[:completed] = is_completed
  session[:success] = "The todo has been successfully updated"
  redirect "/lists/#{params[:id]}"
end

post "/lists/:id/complete_all" do
  @list = session[:lists].find { |list| list[:id] == params[:id].to_i }
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "The todos has been marked as completed"
  redirect "/lists/#{params[:id]}"
end


# not_found do
#   redirect "/"
# end
