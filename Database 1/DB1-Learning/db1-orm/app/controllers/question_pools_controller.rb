class QuestionPoolsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  
  def index
    @question_pools = QuestionPool.all
    render json: @question_pools.as_json(methods: :questions_count)
  end

  def show
    @question_pool = QuestionPool.find(params[:id])
    render json: @question_pool.as_json(
      methods: :questions_count,
      include: {
        questions: {
          only: [:id, :text, :correct_answer, :difficulty_level]
        }
      }
    )
  end

  def create
    @question_pool = QuestionPool.new(question_pool_params)
    if @question_pool.save
      render json: @question_pool.as_json(methods: :questions_count), status: :created
    else
      render json: @question_pool.errors, status: :unprocessable_entity
    end
  end

  private

  def question_pool_params
    params.require(:question_pool).permit(:title, :description)
  end
end