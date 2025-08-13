class Stage < ApplicationRecord
    belongs_to :workflow
    belongs_to :user, optional: true
    has_one :form, dependent: :destroy
    before_create :set_default_position
    has_many :running_stages, dependent: :destroy

    # Title must be present, max 128 chars, allows letters, numbers, spaces, punctuation
    validates :title, presence: true, length: { maximum: 128 }, format: { with: /\A[\p{L}\p{N}\s\p{Punct}]+\z/u, message: "only allows letters, numbers, spaces, and punctuation" }
    # Editor of a stage (maybe feature)
    validates :user_id, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    # Position is optional, but if present must be a positive integer (order of the stage)
    validates :position, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    private

    # Set default position as max position + 1 if position not already set
    def set_default_position
        if self.position.nil?
            self.position ||= (workflow&.stages&.maximum(:position) || 0) + 1
        end
    end
end
