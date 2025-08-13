class Participant < ApplicationRecord
    belongs_to :user
    belongs_to :workflow
    has_one :running_workflow, dependent: :destroy
    
    # current_progress must be integer ≥ 0
    validates :current_progress, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    
    # user_id must be unique per workflow_id
    validates :user_id, uniqueness: { scope: :workflow_id, message: "User already assigned to this workflow" }

    # Update current_progress and save record
    def update_progress(new_progress)
        self.current_progress = new_progress
        save!
    end
    
    # Remove participant record
    def remove_participant
        destroy
    end
    
    # Return string summarizing participant's workflow info
    def view_participant_workflow
        "Participant ID: #{user_id}, Workflow ID: #{workflow_id}, Current Progress: #{current_progress}"
    end
end
