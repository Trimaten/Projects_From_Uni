class FilledFormfield < ApplicationRecord
  belongs_to :filled_form
  belongs_to :formfield

  validates :filled_form_id, :formfield_id, presence: true  # Ensure both associations are present
  validates :value, presence: true  # Ensure the field has a value
end
