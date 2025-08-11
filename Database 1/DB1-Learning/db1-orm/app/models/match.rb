class Match < ApplicationRecord
  belongs_to :question_pool
  has_and_belongs_to_many :questions
  has_many :player_matches
  has_many :players, through: :player_matches

  after_create :assign_questions

  private

  def assign_questions
    self.questions = question_pool.questions.sample(rounds_count)
  end
end