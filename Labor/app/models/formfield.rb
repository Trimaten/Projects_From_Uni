class Formfield < ApplicationRecord
  belongs_to :form
  has_many :filled_formfields, dependent: :destroy

  # Default ordering by position when querying form fields
  default_scope { order(:position) }
  
  # Callback to set a default position before creating a new form field
  before_create :set_default_position

  # Enum for the different types of form fields, with prefix for method names
  enum :typefield, {
    text: 0, number: 1, date: 2, select: 3, checkbox: 4,
    radio: 5, textarea: 6, file: 7, email: 8, url: 9, phone: 10
  }, prefix: :formfield_

  # variableName optional, max 128 chars, specific format allowed
  validates :variableName, length: { maximum: 128 }, format: { with: /\A[\w\s\p{Punct}]+\z/, message: "only allows letters, numbers, spaces, and special characters" }, allow_blank: true
  # title required, max 128 chars, specific format allowed
  validates :title, presence: true, length: { maximum: 128 }, format: { with: /\A[\w\s\p{Punct}]+\z/u, message: "only allows letters, numbers, spaces, and special characters" }
  # form_id required, must be positive integer
  validates :form_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  # typefield required, must be valid enum key
  validates :typefield, presence: true, inclusion: { in: typefields.keys, message: "%{value} is not a valid field type" }

  # Converts JSON stored in content attribute to array, returns empty array on parse error
  def content_array
    JSON.parse(content.presence || "[]")
  rescue JSON::ParserError
    []
  end

  # Sets the content attribute by converting an array to JSON string (rejects blank values)
  def content_array=(arr)
    self.content = arr.reject(&:blank?).to_json
  end

  # Override setter for content attribute to handle arrays and JSON strings gracefully
  def content=(value)
    if value.is_a?(Array)
      super(value.reject(&:blank?).to_json)
    elsif value.is_a?(String)
      begin
        parsed = JSON.parse(value)
        super(parsed.is_a?(Array) ? parsed.reject(&:blank?).to_json : value)
      rescue
        super(value)
      end
    else
      super(value)
    end
  end

  private

  # Sets the position for the new form field to one more than the current max position
  def set_default_position
    self.position ||= (form.form_fields.maximum(:position) || 0) + 1
  end
end
