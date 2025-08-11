require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
  end

  test "should save question with valid parameters" do
    question = Question.new(
      text: "What is the capital of France?",
      correct_answer: "Paris",
      difficulty_level: 1,
      question_pool: @question_pool
    )
    assert question.save, "Failed to save the question with valid parameters"
  end
  puts "Question model tests finished"
end