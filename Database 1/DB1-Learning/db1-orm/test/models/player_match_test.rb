require "test_helper"

class PlayerMatchTest < ActiveSupport::TestCase
  setup do
    @player = Player.create!(name: "Test Player")
    @match = Match.create!(
      question_pool: QuestionPool.create!(title: "General Knowledge", description: "Questions covering various topics"),
      start_time: Time.now,
      end_time: Time.now + 1.hour,
      rounds_count: 5
    )
  end

  test "should create player_match association" do
    player_match = PlayerMatch.create!(player: @player, match: @match)

    assert_equal @player, player_match.player
    assert_equal @match, player_match.match
  end
  puts "PlayerMatch model tests finished"
end