ENV["RACK_ENV"] = "test"

require "fileutils"
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

  def setup
    FileUtils.mkdir_p(data_path)
    create_document("about.md", "#this is a test")
    create_document("changes.txt", "this is a test")
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def sign_in
    post "/users/sign_in", username: "admin", password: "secret"
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { signed_in: true } }
  end

  def test_root
    get "/"
    assert_equal 302, last_response.status
    assert_includes last_response["Location"], "index"
    get last_response["Location"]
    assert_equal 200, last_response.status
  end

  def test_index
    get "/index", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_files
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    content = "this is a test"
    assert_includes last_response.body, content
  end

  def test_show_does_not_exist_when_no_file
    get "/tartampion.txt"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_request.session, :failure)
    assert_includes(last_request.session[:failure], "does not exist")

    get last_response["Location"] # Request the page that the user was redirected to
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "does not exist")
  end

  # test/cms_test.rb
  def test_viewing_markdown_document
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>this is a test</h1>"
  end

  # test/cms_test.rb
  def test_editing_document
    get "/changes.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_cannot_edit_document_when_signed_out
    get "/changes.txt/edit"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Sign in"
  end

  def test_updating_document
    # sign_in
    post "/changes.txt", { content: "new content" }, admin_session

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been successfully updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_updating_document_signed_out
    post "/changes.txt", {content: "new content"}

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:failure]
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "submit"
  end

  def test_view_new_document_form_signed_out
    get "/new"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:failure]
  end

  def test_create_new_document
    post "/create", { document: "test.txt" }, admin_session
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt was created"

    get "/index"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_signed_out
    post "/create", { document: "test.txt" }

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:failure]
  end

  def test_create_new_document_without_filename
    post "/create", { document: "" } , admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_deleting_document_signed_out
    create_document("test.txt")

    post "/test.txt/destroy"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:failure]
  end


  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/destroy", {}, admin_session

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been successfully deleted"

    get "/index"
    refute_includes last_response.body, "test.txt"
  end

  # test/cms_test.rb
  def test_signin_form
    get "/users/sign_in"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "submit"
  end

  def test_signin
    post "/users/sign_in", username: "admin", password: "secret"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Welcome"
    assert_includes last_response.body, "Signed in as admin"
  end

   def test_signin
    post "/users/sign_in", username: "louis", password: "braille"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "Welcome"
    assert_includes last_response.body, "Signed in as louis"
  end

  def test_signin_with_bad_credentials
    post "/users/sign_in", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signout
    sign_in
    get last_response["Location"]
    assert_includes last_response.body, "Welcome"

    post "/users/sign_out"
    get last_response["Location"]
    assert_includes last_response.body, "You have been signed out"
    assert_includes last_response.body, "Sign in"
  end

end
