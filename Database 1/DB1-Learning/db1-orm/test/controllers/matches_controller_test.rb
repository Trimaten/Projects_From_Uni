require "test_helper"

class MatchTest < ActiveSupport::TestCase
  setup do
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    10.times do |i|
      Question.create!(
        text: "Question #{i + 1}",
        correct_answer: "Answer #{i + 1}",
        difficulty_level: 1,
        question_pool: @question_pool
      )
    end
  end

  test "assign_questions callback assigns questions" do
    match = Match.create!(
      question_pool: @question_pool,
      start_time: Time.now,
      end_time: Time.now + 1.hour,
      rounds_count: 5
    )

    assert_equal 5, match.questions.count
  end
  puts "Match controller tests finished"
end