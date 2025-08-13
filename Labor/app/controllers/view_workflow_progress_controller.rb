class ViewWorkflowProgressController < ApplicationController
  # Ensure only logged-in users can access actions
  before_action :authenticate_user!
  # Ensure set_workflow is called for both index and the new action
  before_action :set_workflow, only: [:index, :continue_workflow] 

  def index
    @banner_title = "Workflow Progress"
    user_id = current_user.id
    # @workflow is set by before_action :set_workflow
    
    @participant = Participant.find_by(user_id: user_id, workflow_id: @workflow.id)

    # Check if the user is a participant in the workflow
    if @participant.nil?
      redirect_to workflows_path, alert: "You are not a participant in this workflow."
    end

    @participant.reload
    
    # Fetch stages ordered by their position attribute for consistent flow
    @stages = @workflow.stages.order(:position) 
    
    # @current_stage_count should reflect the progress.
    # Assuming it's the 0-indexed position of the *last completed* stage,
    # or 0 if no stages completed yet.
    @current_stage_count = @participant&.current_progress || 0 

    # Get previous stage to check if filledForm is approvable
    previous_stage_position = @current_stage_count - 1
    if previous_stage_position >= 0
      previous_stage = @stages[previous_stage_position]
      if previous_stage&.approvable
        previous_form = previous_stage.form
        if previous_form.present?
          @previous_filled_form = FilledForm.find_by(user: current_user, form: previous_form)
        end
      end
    end

    @workflow_status = @workflow.status
    @workflow_title = @workflow.title
    @workflow_owner = @workflow.owner
    @workflow_id = @workflow.id

    
    # Render the view with the workflow progress
    render :index
  end

  # NEW METHOD: Redirects to the next form to be filled
  def continue_workflow
    user_id = current_user.id
    # @workflow is set by before_action :set_workflow

    @participant = Participant.find_by(user_id: user_id, workflow_id: @workflow.id)

    # If the user is not a participant, redirect them
    if @participant.nil?
      flash[:alert] = "You are not a participant in this workflow."
      redirect_to workflow_overview_path(@workflow) and return
    end
    
    current_stage_position = @participant.current_progress
    current_stage = @workflow.stages.find_by(position: current_stage_position)
    
    # Check if stage has a form 
    if current_stage&.form.present? && current_stage.approvable?
      filled_form = FilledForm.find_by(form: current_stage.form, user: current_user)
      Rails.logger.debug "Current Stage: #{current_stage.inspect}"
      Rails.logger.debug "Filled form for user #{current_user.id}: #{filled_form.inspect}"  
      
      # Inform user about approval need if not already done by the workflow owner
      if filled_form.nil? || !filled_form.approved? || filled_form.submitted_at.nil?
        flash[:alert] = "Please wait for approval of your submitted form before proceeding to the next stage."
        redirect_to workflow_progress_path(@workflow.id) and return
      end
    end

    # Determine the position of the *next* stage to be completed.
    # Assuming current_progress stores the 0-indexed position of the last completed stage.
    # So, if current_progress is 0, the next stage is position 1.
    # If current_progress is 1, the next stage is position 2, and so on.
    next_stage_position = current_stage_position + 1


    # Find the next stage based on its position within the workflow
    next_stage = @workflow.stages.find_by(position: next_stage_position)

    # If there's no next stage (meaning all stages are completed)
    if next_stage.nil?
      flash[:notice] = "You have completed all stages of this workflow! 🎉"
      redirect_to workflow_progress_path(@workflow.id) # Stay on progress page or redirect to a completion page
      Rails.logger.info "No next stage found for workflow #{@workflow.id} at position #{next_stage_position}."
      return
    end

    # If the next stage exists, check if it has a form
    if next_stage.form.present?
      # Redirect to the 'fill' action of the form associated with this stage
      # The helper is fill_workflow_form_path(@workflow, form_id)
      Rails.logger.info "Redirecting to fill form for stage: #{next_stage.title} (ID: #{next_stage.form.id})"
      redirect_to fill_workflow_form_path(@workflow, next_stage.form.id)
    else
      # If the next stage doesn't have a form, alert the user and stay on progress page
      flash[:alert] = "The stage '#{next_stage.title}' does not have a form to fill. Please proceed to the next step manually."
      redirect_to workflow_progress_path(@workflow.id)
    end

  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Workflow or associated data not found. Please try again."
    redirect_to dashboard_path # Fallback to a safer path if workflow isn't found during processing
  rescue => e
    flash[:alert] = "An unexpected error occurred: #{e.message}"
    Rails.logger.error "Error in continue_workflow: #{e.message}" # Log the error for debugging
    redirect_to workflow_progress_path(@workflow.id) # Fallback
  end

  private

  # Helper method to find the workflow, used by before_action
  def set_workflow
    @workflow = Workflow.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Workflow not found."
    redirect_to search_path and return
  end
end