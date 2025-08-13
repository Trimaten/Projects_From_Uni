class RunningStage < ApplicationRecord
  belongs_to :running_workflow
  belongs_to :stage

  # Allowed status values
  STATUSES = %w[pending in_progress completed skipped]

  # status must be one of the STATUSES
  validates :status, inclusion: { in: STATUSES }

  # Return string with stage title and status
  def to_s
    "#{stage.title} - #{status}"
  end
end
