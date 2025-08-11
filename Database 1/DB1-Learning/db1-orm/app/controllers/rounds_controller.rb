class RoundsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:play]

  def show
    @round = Round.find(params[:id])
    render json: @round
  end

  def play
    @round = Round.find(params[:id])
    @player = Player.find(params[:player_id])
    @answers = params[:answers]
    @player.submit_answers(@round, @answers)
    render json: { message: 'Answers submitted successfully', score: @player.score }
  end
end