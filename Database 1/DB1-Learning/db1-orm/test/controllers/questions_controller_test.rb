require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
  end

  test "should create question" do
    assert_difference("Question.count") do
      post questions_url, params: { question: { text: "What is the capital of France?", correct_answer: "Paris", difficulty_level: 1, question_pool_id: @question_pool.id } }, as: :json
    end
    assert_response :created
  end
  puts "Questions controller tests finished"
end