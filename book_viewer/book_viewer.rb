require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'pry'
before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index { |paragraph, idx| "<p id='#{idx + 1}'> #{paragraph}</p>" }.join
  end

  def bold_query(text,query)
    text.gsub(query, "<strong>#{query}</strong>")
  end


end

get "/" do
  @title = "The adventures of Sherlock Holmes"
  erb :home
end

get "/search" do
  query = params[:query]

  if query
    files = Dir.entries("data").reject do |name|
      name == "toc.txt" || File.directory?(name)
    end
    
    paragraphs_in_files = files.each_with_object({}) do |chapter, hsh| 
      paragraphs = File.read("data/" + chapter).split(("\n\n"))
                                               .each_with_object({}).with_index do |(par, list), idx| 
                                                list[idx] = par
                                               end
      hsh[ chapter.gsub(/[chp\.tx]/, "" )] = paragraphs
    end

    chapters_found = paragraphs_in_files.each_with_object({}) do |(idx, chapter), paragraphs|
      found_paragraphs = chapter.select { |idx, paragraph| paragraph.include?(query) }
      next if found_paragraphs.empty?
      paragraphs[idx] = found_paragraphs
    end

    @results = chapters_found
    puts @results["1"]
  end
  erb:search
end

get "/chapters/:number" do
  @number = params[:number]
  @title = @contents[@number.to_i - 1]

  # redirect "/" unless (1..@contents.size).cover? @number


  @chapter = File.read("data/chp#{@number}.txt")
  erb :chapter
end

not_found do
  redirect "/"
end
