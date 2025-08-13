class StagesController < ApplicationController
  # Ensure the user is logged in before accessing any actions
  before_action :authenticate_user!
  # Set the associated workflow for the stage actions
  before_action :set_workflow
  # Set the stage for actions that require an existing stage
  before_action :set_stage, only: [:edit, :update, :participant_form]

  # Renders a form to create a new stage
  def new
    @stage = @workflow.stages.build
  end

  # Handles creation of a new stage within a workflow
  def create
    @stage = @workflow.stages.build(stage_params)

    if @stage.save
      Rails.logger.debug "New stage created with position: #{@stage.position}"
      redirect_to workflow_path(@workflow), notice: 'Stage was successfully created.'
    else
      render :new
    end
  end

  # Renders the edit form for a specific stage
  def edit
    # Used for reordering stages via drag-and-drop in the UI
    @stage_order = @workflow.stages.order(:position).pluck(:id).join(",")
    @form = @stage.form

    if @form
      # Load all participants who have submitted the form for this stage
      @participants_with_answers = Participant
        .includes(:user)
        .joins(user: :filled_forms)
        .where(workflow_id: @workflow.id, filled_forms: { form_id: @form.id })
        .distinct

      # If a user is selected, load their filled form data for display
      if params[:selected_user_id]
        @selected_user = User.find(params[:selected_user_id])
        @filled_form = FilledForm.includes(filled_formfields: :formfield)
                                .find_by(user: @selected_user, form: @form)
      end
    else
      # If no form is assigned to the stage, no participant data is loaded
      @participants_with_answers = []
    end
  end

  # Handles updates to a stage (e.g. title, position, approval)
  def update
    # Reload participants with answers for use in the view
    @participants_with_answers = Participant
      .includes(:user)
      .joins(user: :filled_forms)
      .where(workflow_id: @workflow.id, filled_forms: { form_id: @stage.form.id })
      .distinct
    if @stage.update(stage_params)
      # Set filledForm to approved when updated
      if params[:filled_form].present? && params[:filled_form][:id].present?
        filled_form = FilledForm.find_by(id: params[:filled_form][:id])
        if filled_form && filled_form.form_id == @stage.form.id
          approved_value = params[:filled_form][:approved] == "1"
          filled_form.update(approved: approved_value)
        end
      end

      # Sort Stages by index 
      if params[:stage][:stage_order].present?
        stage_ids = params[:stage][:stage_order].split(',').map(&:to_i)
        stage_ids.each_with_index do |id, index|
          stage = @workflow.stages.find_by(id: id)
          stage.update(position: index + 1) if stage
        end
      end
      redirect_to workflow_path(@workflow), notice: 'Stage updated.'
    else
      render :edit
    end
  end

  # AJAX endpoint to display a participant's form responses within a stage
  def participant_form
    @filled_form = FilledForm.includes(filled_formfields: :formfield)
                             .find_by(form: @stage.form, user_id: params[:user_id])
    @filled_formfields = @filled_form&.filled_formfields || []

    if @filled_formfields.any?
      render inline: <<-ERB
        <div class="w-full space-y-4 text-left">
          <% @filled_formfields.each do |filled_field| %>
            <div class="bg-white p-4 rounded shadow">
              <p class="text-sm text-gray-600 font-medium"><%= filled_field.formfield.label %></p>
              <p class="text-lg text-gray-900"><%= filled_field.value %></p>
            </div>
          <% end %>
        </div>
      ERB
    else
      # Show fallback message if there are no filled fields
      render inline: "<p class='text-red-500'>No filled fields available.</p>", layout: false
    end
  end

  private

  # Find and assign the current workflow from the URL params
  def set_workflow
    @workflow = Workflow.find(params[:workflow_id])
  end

  # Find the current stage within the workflow; redirect if not found
  def set_stage
    @stage = @workflow.stages.find_by(id: params[:id])
    redirect_to workflow_path(@workflow), alert: "Stage not found." unless @stage
  end

  # Strong parameters to allow only permitted stage attributes
  def stage_params
    params.require(:stage).permit(:title, :approvable)
  end
end
