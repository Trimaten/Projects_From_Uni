require "test_helper"

class QuestionPoolTest < ActiveSupport::TestCase
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    5.times do |i|
      Question.create!(
        text: "Question #{i + 1}",
        correct_answer: "Answer #{i + 1}",
        difficulty_level: 1,
        question_pool: @question_pool
      )
    end
  end

  test "should return correct number of questions" do
    assert_equal 5, @question_pool.questions.count, "Failed to return the correct number of questions"
  end
  puts "QuestionPool model tests finished"
end