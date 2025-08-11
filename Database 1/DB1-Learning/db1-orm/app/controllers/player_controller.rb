class PersonController < ApplicationController
    def join_match
      @player = Player.find(params[:id])
      @match = Match.find(params[:match_id])
      @player.join_match(@match)
      render json: @match, include: :persons
    end
  
    def play_round
      @player = Player.find(params[:id])
      @round = Round.find(params[:round_id])
      @player.submit_answers(@round, params[:answers])
      render json: @round.questions
    end
  
    def leaderboard
      @match = Match.find(params[:match_id])
      @leaderboard = @match.player.order(score: :desc)
      render json: @leaderboard
    end
  end