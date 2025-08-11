class MatchesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :join, :play]

  def create
    @match = Match.new(match_params)
    @match.end_time = @match.start_time + 1.hour
    if @match.save
      render json: {
        match_id: @match.id,
        questions: adjusted_questions(@match.questions)
      }, status: :created
    else
      render json: @match.errors, status: :unprocessable_entity
    end
  end

  def show
    @match = Match.find(params[:id])
    render json: {
      match_id: @match.id,
      question_pool_id: @match.question_pool_id,
      start_time: @match.start_time,
      end_time: @match.end_time,
      rounds_count: @match.rounds_count,
      players_count: @match.players.count,
      players: @match.players.as_json(only: [:id, :name, :score]),
      questions: adjusted_questions(@match.questions)
    }
  end

  def join
    @match = Match.find(params[:match_id])
    @player = Player.find(params[:player_id])
    @match.players << @player
    render json: @match
  end

  def play
    @match = Match.find(params[:match_id])
    @player = Player.find(params[:player_id])
    @answers = params[:answers]
    results = @player.submit_answers(@match, @answers)
    render json: { message: 'Answers submitted successfully', score: @player.score, results: results }
  end

  def leaderboard
    @match = Match.find(params[:id])
    @leaderboard = @match.players.order(score: :desc)
    render json: @leaderboard 
  end

  private

  def match_params
    params.require(:match).permit(:question_pool_id, :start_time, :rounds_count)
  end

  def adjusted_questions(questions)
    questions.each_with_index.map do |question, index|
      question.as_json(only: [:text, :difficulty_level]).merge(id: index + 1)
    end
  end
end