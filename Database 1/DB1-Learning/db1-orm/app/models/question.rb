class Question < ApplicationRecord
  belongs_to :question_pool
  belongs_to :round, optional: true
end