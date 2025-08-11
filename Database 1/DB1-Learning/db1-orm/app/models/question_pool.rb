class QuestionPool < ApplicationRecord
  has_many :questions
  has_many :matches

    def questions_count
      questions.count
    end
  end