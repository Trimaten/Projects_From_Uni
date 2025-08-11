require "test_helper"

class QuestionPoolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
  end

  test "should get index" do
    get question_pools_url, as: :json
    assert_response :success
  end

  test "should show question pool" do
    get question_pool_url(@question_pool), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @question_pool.id, json_response["id"]
  end

  test "should create question pool" do
    assert_difference("QuestionPool.count") do
      post question_pools_url, params: { question_pool: { title: "Geography", description: "Questions about geography" } }, as: :json
    end
    assert_response :created
  end
  puts "QuestionPool controller tests finished"
end