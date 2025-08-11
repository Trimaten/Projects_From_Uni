require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "should not save match without question_pool" do
    match = Match.new
    assert_not match.save, "Saved the match without a question_pool"
  end

  test "should save match with valid parameters" do
    question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    match = Match.new(question_pool: question_pool, start_time: Time.now, end_time: Time.now + 1.hour, rounds_count: 5)
    assert match.save, "Failed to save the match with valid parameters"
  end

  test "should assign questions based on rounds_count" do
    question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    10.times do |i|
      Question.create!(text: "Question #{i + 1}", correct_answer: "Answer #{i + 1}", difficulty_level: 1, question_pool: question_pool)
    end

    match = Match.create!(question_pool: question_pool, start_time: Time.now, end_time: Time.now + 1.hour, rounds_count: 5)
    assert_equal 5, match.questions.count, "Failed to assign the correct number of questions"
  end

  puts "Match model tests finished"
end