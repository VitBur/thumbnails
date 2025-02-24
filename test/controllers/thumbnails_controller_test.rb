require 'test_helper'

class ThumbnailsControllerTest < ActionDispatch::IntegrationTest
  test "should get generate" do
    get thumbnails_generate_url
    assert_response :success
  end

end
