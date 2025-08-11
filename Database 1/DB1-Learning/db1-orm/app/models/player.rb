class Player < ApplicationRecord
  has_many :player_matches
  has_many :matches, through: :player_matches

  def submit_answers(match, answers)
    results = []
    answers.each do |answer|
      question = match.questions.find_by(id: answer[:question_id])
      if question && question.correct_answer == answer[:answer]
        self.score += 1
        results << { question_id: question.id, correct: true }
      else
        results << { question_id: answer[:question_id], correct: false }
      end
    end
    self.save
    results
  end
end