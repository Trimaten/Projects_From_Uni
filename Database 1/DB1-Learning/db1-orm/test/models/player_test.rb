require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(name: "Test Player")
    @question_pool = QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics")
    @match = Match.create!(
      question_pool: @question_pool,
      start_time: Time.now,
      end_time: Time.now + 1.hour,
      rounds_count: 5
    )
    @question1 = Question.create!(
      text: "What is the capital of France?",
      correct_answer: "Paris",
      difficulty_level: 1,
      question_pool: @question_pool
    )
    @question2 = Question.create!(
      text: "What is the capital of Spain?",
      correct_answer: "Madrid",
      difficulty_level: 1,
      question_pool: @question_pool
    )
    @match.questions << [@question1, @question2]
  end

  test "submit_answers updates score" do
    answers = [
      { question_id: @question1.id, answer: "Paris" }, # Correct answer
      { question_id: @question2.id, answer: "Barcelona" } # Incorrect answer
    ]

    results = @player.submit_answers(@match, answers)
    @player.reload

    assert_equal 1, @player.score, "Player score was not updated correctly"
    assert_equal 2, results.size, "Incorrect number of results returned"
    assert_equal true, results[0][:correct], "First answer should be correct"
    assert_equal false, results[1][:correct], "Second answer should be incorrect"
  end
  puts "Player model tests finished"
end