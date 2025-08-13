class WorkflowoverviewController < ApplicationController
  # Ensure only logged-in users can access actions
  before_action :authenticate_user!

  # Load the workflow from database before executing :show and :start actions
  before_action :set_workflow, only: [:show, :start]

  # Displays workflow overview page
  def show
    @banner_title = "Workflow overview"
    @workflow = Workflow.find(params[:id])  # Redundant with set_workflow, but ensures data is fresh
    @author = @workflow.owner
    @number_of_stages = @workflow.stages.count
    @stages = @workflow.stages.order(:position)
  rescue ActiveRecord::RecordNotFound
    # Handle case where workflow with given ID does not exist
    flash[:alert] = "Workflow not found."
    redirect_to search_path
  end

  # Handles user joining a workflow
  def start
    unless current_user
      # Additional safety check in case before_action was bypassed
      flash[:alert] = "You must be logged in to join a workflow."
      redirect_to new_user_session_path and return
    end

    initial_progress_value = 0

    # Find or initialize participant record for current user in this workflow
    @participant = Participant.find_or_initialize_by(
      user_id: current_user.id,
      workflow_id: @workflow.id
    )

    if @participant.new_record? # Only set progress if it's a new participant
      @participant.current_progress = initial_progress_value
    end

    # Attempt to save the participant record
    if @participant.save
      flash[:notice] = "You have successfully joined the workflow '#{@workflow.title}'!"
      # Immediately redirect to the progress view after successful participation
      redirect_to workflow_progress_path(@workflow.id)
    else
      flash[:alert] = "Failed to join workflow: #{@participant.errors.full_messages.to_sentence}"
      # If saving fails, you should render the show page again so the user sees the errors
      # Ensure all @variables required by the show template are set here.
      @author = @workflow.owner
      @number_of_stages = @workflow.stages.count
      @stages = @workflow.stages.order(:position)
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    # Gracefully handle missing workflow
    flash[:alert] = "Workflow not found."
    redirect_to search_path
  rescue => e
    # Catch-all rescue to handle unexpected errors and avoid crashing the app
    flash[:alert] = "An unexpected error occurred: #{e.message}"
    redirect_to workflow_overview_path(@workflow)
  end

  private

  # Loads the workflow by ID; used as a before_action
  def set_workflow
    @workflow = Workflow.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Workflow not found."
    redirect_to search_path and return
  end

  # Stores recent workflows in session (not currently used in this controller)
  def store_recent_workflow(workflow_id)
    session[:recent_workflow_ids] ||= []
    session[:recent_workflow_ids].delete(workflow_id)
    session[:recent_workflow_ids].unshift(workflow_id)
  end
end