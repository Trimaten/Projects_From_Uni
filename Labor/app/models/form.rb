class Form < ApplicationRecord
    has_many :form_fields, class_name: 'Formfield', dependent: :destroy
    has_many :filled_forms, dependent: :destroy
    belongs_to :stage

    # Allows nested attributes for form_fields in forms, so fields can be created/updated together with the form
    accepts_nested_attributes_for :form_fields, allow_destroy: true

    # Validations: Title must be present, max 128 characters, and allow letters, numbers, spaces, special characters (including German umlauts)
    validates :title, presence: true, length: { maximum: 128 }, format: { with: /\A[\w\s\p{Punct}]+\z/u, message: "only allows letters, numbers, spaces, and special characters" }
end
