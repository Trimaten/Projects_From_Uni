class Round < ApplicationRecord
  belongs_to :match
  belongs_to :question
end