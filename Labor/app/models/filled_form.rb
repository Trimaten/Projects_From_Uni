class FilledForm < ApplicationRecord
  belongs_to :form
  belongs_to :user
  has_many :filled_formfields, dependent: :destroy

  validates :form_id, presence: true  # Ensure the form_id is present (cannot be null)
end
