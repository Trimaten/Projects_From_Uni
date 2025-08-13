class DashboardController < ApplicationController
  # Ensure the user is authenticated before accessing any action in this controller
  before_action :authenticate_user!

  # Displays the user's dashboard
  def index
    @user = current_user

    # Fetch workflows owned by the current user
    @user_workflows = Workflow.all.where(owner_id: @user.id)

    # Fetch workflows the user has been invited to (as a participant)
    @invited_workflows = Participant.where(user_id: @user.id).includes(:workflow).map(&:workflow)

    # Get recently visited workflows
    recent_ids = session[:recent_workflow_ids] || []
    @recent_workflows = Workflow  # Find recently visited workflow if u are an participant of the workflow
    .joins(:participants)
    .where(id: recent_ids, participants: {user_id: @user.id})
    .distinct

    # Preserve the order of recent_ids in the result list
    @recent_workflows = recent_ids.map { |id| @recent_workflows.find { |w| w.id == id } }.compact

    # Set the page banner title
    @banner_title = "Dashboard"
  end
  
  # Fallback method for new action; sets the same banner title
  def new
    @banner_title = "Dashboard"
    super
  end
  
end
