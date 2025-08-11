class QuestionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @question = Question.new(question_params)
    if @question.save
      render json: @question, status: :created
    else
      render json: @question.errors, status: :unprocessable_entity
    end
  end

  private

  def question_params
    params.require(:question).permit(:text, :correct_answer, :difficulty_level, :question_pool_id)
  end
end