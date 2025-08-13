class RunningWorkflow < ApplicationRecord
  belongs_to :participant
  has_many :running_stages, dependent: :destroy
  has_many :stages, through: :running_stages

  # Ensure one running workflow per participant
  validates :participant_id, uniqueness: true

  # After creating a running workflow, set up its stages
  after_create :initialize_running_stages

  private

  # Create running stages for each stage in the workflow, initially pending
  def initialize_running_stages
    participant.workflow.stages.order(:position).each do |stage|
      running_stages.create!(stage: stage, status: 'pending')
    end
  end
end
