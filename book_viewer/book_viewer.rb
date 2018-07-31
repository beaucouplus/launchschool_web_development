require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  @contents = File.readlines("data/toc.txt")
  erb :home
end

get "/chapters/:number" do |n|
  @title = "Chapter #{n}"
  @contents = File.readlines("data/toc.txt")
  @chapter = File.read("data/chp#{n}.txt")
  erb :chapter
end
