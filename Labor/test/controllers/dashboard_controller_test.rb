require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get url" do
    get root_url #root url is dashboard url
    assert_response :success
  end

end
