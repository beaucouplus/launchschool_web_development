require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @contents = File.readlines("data/toc.txt")
  @title = "The adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do 
  @number = params[:number]
  @contents = File.readlines("data/toc.txt")
  @title = @contents[@number.to_i - 1]
  @chapter = File.read("data/chp#{@number}.txt")
  erb :chapter
end
