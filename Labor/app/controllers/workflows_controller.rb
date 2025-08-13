class WorkflowsController < ApplicationController
  # Constant to define how many recent workflows to store in session (prevent overflow)
  RECENT_WORKFLOWS_NUMBER = 7

  # Load the workflow from the database for relevant actions
  before_action :set_workflow, only: [:show, :edit, :update, :destroy, :start, :view_stage]

  # Ensure user is authenticated for creating workflows
  before_action :authenticate_user!, only: [:new, :create]

  # Lists all workflows
  def index
    @workflows = Workflow.all
  end

  # Shows details for a specific workflow
  def show
    puts "Current stage ID: #{@workflow.current_stage}"
    puts @form_present

    @workflow = Workflow.find(params[:id]) 

    #used for recent workflows - only for session as of now TODO maybe make it persistent in the future
    store_recent_workflow(@workflow.id)

    # Load current stage and check if it has a form
    if @workflow.stages.present?
      @stage = @workflow.stages.find_by(id: @workflow.current_stage)
      @form_present = @stage&.form.present?
      puts @form_present
    end
  end

  # Renders form for creating a new workflow
  def new
    @banner_title = "Creating a new Workflow"
    @workflow = Workflow.new
    @workflow.owner_id = current_user.id
    @workflow.status = 'draft'
  end

  # Handles submission of the workflow creation form
  def create
    @workflow = Workflow.new(workflow_params)
    @workflow.owner_id = current_user.id
    @workflow.status = 'draft'
    if @workflow.save
      redirect_to @workflow, notice: "Workflow was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Renders the edit form for a workflow
  def edit; end

  # Updates an existing workflow
  def update
    @workflow = Workflow.find(params[:id])
    if @workflow.update(workflow_params)
      redirect_to dashboard_path, notice: 'Workflow erfolgreich gespeichert.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Deletes a workflow
  def destroy
    @workflow.destroy
    redirect_to dashboard_path, notice: "Workflow was deleted."
  end

  # Triggers the logic to start a workflow
  def start
    @workflow.start_workflow
    redirect_to @workflow, notice: "Workflow has been started."
  end

  # View current stage (Debug purposes)
  def view_stage
    render plain: @workflow.view_stage
  end

  # Adds a new stage to the workflow and optionally sets it as current
  def add_stage
    @workflow = Workflow.find(params[:id])
    stage = @workflow.add_stage
    @workflow.update(current_stage: stage.id) if stage.persisted? && @workflow.current_stage != stage.id
    redirect_to @workflow, notice: "New stage added successfully."
  end

  # Manually sets the current stage of the workflow
  def set_current_stage
    @workflow = Workflow.find(params[:id])
    if @workflow.update(current_stage: params[:stage_id])
      redirect_to @workflow, notice: "Current stage was successfully updated."
    else
      redirect_to @workflow, alert: "Failed to set current stage."
    end
  end

  # Add a form to a specific stage (auto generated when creating a new stage)
  def add_form_to_stage
    @workflow = Workflow.find(params[:id])
    @stage = @workflow.stages.find_by(id: params[:stage_id])

    if @stage.nil?
      redirect_to @workflow, alert: "Stage not found."
      return
    end

    if @stage.form.present?
      redirect_to @workflow, alert: "A form already exists for this stage."
      return
    end

    form = @stage.create_form(title: "Form for Stage #{@stage.id}")

    if form.persisted?
      redirect_to @workflow, notice: "Form was successfully created."
    else
      redirect_to @workflow, alert: "Failed to create form."
    end
  end

  # Invites a user to become a participant in the workflow
  def invite_participant
    @workflow = Workflow.find(params[:id])
    user = User.find(params[:user_id])

    participant = Participant.find_or_initialize_by(user: user, workflow: @workflow)

    # Check if participant is already invited
    if participant.persisted?
      flash[:notice] = "#{user.username} is already a participant."
    else
      participant.current_progress = 0  # Set workflow progress of user to 0 (start)
      if participant.save
        RunningWorkflow.create!(participant: participant)
        flash[:notice] = "#{user.username} has been invited."
      else
        flash[:alert] = "Failed to invite: #{participant.errors.full_messages.to_sentence}"
      end
    end

    redirect_to workflow_path(@workflow)
  end

  # Accept invitation to a workflow by signed-in user
  def accept_invite
    # Check if user is already signed in
    unless current_user
      redirect_to login_path, alert: "Please log in to join the workflow."
      return
    end

    @workflow = Workflow.find(params[:id])

    # Check if user is already a participant of workflow
    unless @workflow.participants.exists?(user_id: current_user.id)
      # Create participant
      @workflow.participants.create(user: current_user)
      flash[:notice] = "You have successfully joined the workflow."
    else
      flash[:notice] = "You are already a participant."
    end

    redirect_to start_workflow_overview_path(params[:id])
  end

  def change_visibility
    @workflow = Workflow.find(params[:id])
    @workflow.update(public: ActiveModel::Type::Boolean.new.cast(params[:public]))
    redirect_to @workflow, notice: "Visibility updated successfully."
  end

  private

  # Fetches workflow by ID from params
  def set_workflow
    @workflow = Workflow.find(params[:id])
  end

  # Strong parameters for workflow creation/update
  def workflow_params
    params.require(:workflow).permit(:title, :status, :description, :public)
  end

  # Stores recently accessed workflow IDs in the session for quick access
  def store_recent_workflow(workflow_id)
    session[:recent_workflow_ids] ||= []
    session[:recent_workflow_ids].delete(workflow_id)
    session[:recent_workflow_ids].unshift(workflow_id)
    session[:recent_workflow_ids] = session[:recent_workflow_ids].take(RECENT_WORKFLOWS_NUMBER)
  end
end
