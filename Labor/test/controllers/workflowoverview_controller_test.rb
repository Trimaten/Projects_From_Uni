require "test_helper"

class WorkflowoverviewControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @workflow = workflows(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get show" do
    get workflow_overview_url(@workflow)
    assert_response :success
  end
end
