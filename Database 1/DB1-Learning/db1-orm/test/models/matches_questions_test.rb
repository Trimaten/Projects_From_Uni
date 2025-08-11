require "test_helper"

class MatchesQuestionsTest < ActiveSupport::TestCase
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    @match = Match.create!(
      question_pool: @question_pool,
      start_time: Time.now,
      end_time: Time.now + 1.hour,
      rounds_count: 5
    )
    @question = Question.create!(
      text: "What is the capital of France?",
      correct_answer: "Paris",
      difficulty_level: 1,
      question_pool: @question_pool
    )
  end

  test "should associate match with question" do
    @match.questions << @question

    assert_includes @match.questions, @question, "Failed to associate match with question"
  end
  puts "MatchesQuestions model tests finished"
end