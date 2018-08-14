ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"
Minitest::Reporters.use!

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Getting started.", last_response.body
  end

  def test_index
    get "/index"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "about")
  end

  def test_files
    get "/data/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    content = "How much wood\nwould be woodchuck chuck\nif a woodchuck\ncould chuck wood"
    assert_equal content, last_response.body
  end

  def test_show_does_not_exist_when_no_file
    get "data/tartampion.txt"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_request.session, :failure)
    assert_includes(last_request.session[:failure], "does not exist")
    
    get last_response["Location"] # Request the page that the user was redirected to
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "does not exist")
  end

end
