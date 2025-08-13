require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @user = users(:one) # Assign a user from your fixtures
    sign_in @user
    
    @workflow = workflows(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get search_index_url
    assert_response :success
  end

  test "should get search" do
    get search_url
    assert_response :success
  end

  test "should get search with results" do
    get search_path, params: { query: @workflow.title }
    assert_response :success
    assert_select "li", text: /#{@workflow.title}/i
  end

  test "should get search with no results" do
    get search_path, params: { query: "thiswillnotmatchanything" }
    assert_response :success
    assert_select "p", text: "No results found."
  end
end
