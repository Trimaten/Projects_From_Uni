class FormsController < ApplicationController
  # Ensure user is logged in before any action
  before_action :authenticate_user!
  # Load the form and associated workflow before specific actions
  before_action :set_form, only: [:edit, :update, :fill, :add_field, :reorder_field, :destroy_field]

  def create
    # Create a new form linked to a specific stage, if stage_id is provided
    if params[:stage_id].present?
      stage = Stage.find(params[:stage_id])
      @form = Form.create!(title: "Untitled Form", stage: stage)
      redirect_to workflow_path(stage.workflow), notice: "Form created successfully."
    else
      # Redirect back with an alert if no stage_id is present
      redirect_back fallback_location: workflows_path, alert: "No Stage provided."
    end
  end  

  def edit
    # Load form including its fields for editing
    @form = Form.includes(:form_fields).find(params[:id])
  end

  def update
    # Load form for update
    @form = Form.find(params[:id])
    # Track form being filled by current user
    filled_form = FilledForm.create!(form: @form, user: current_user)
    Rails.logger.debug "Params on update: #{params.inspect}"

     # Attempt to update form with submitted parameters
    if @form.update(form_params)
      redirect_to workflow_path(@workflow), notice: "Form saved successfully."
    else
      Rails.logger.debug "Errors: #{@form.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Find and delete the form (feature)
    @form = Form.find(params[:id])
    @form.destroy
    redirect_to forms_path, notice: "Form deleted."
  end

  def destroy_field
    # Attempt to find the form field within the current form
    @form_field = @form.form_fields.find(params[:field_id])

    # Try to destroy the form field
    if @form_field.destroy
      # Log success and return an empty 200 OK response
      flash.now[:notice] = "Form field deleted successfully."
      head :ok
    else
      # Log validation or deletion errors and return a 422 Unprocessable Entity response
      flash.now[:alert] = "Failed to delete form field."
      render json: { error: @form_field.errors.full_messages }, status: :unprocessable_entity
    end
  # Handle case where the field is not found
  rescue ActiveRecord::RecordNotFound
    # Log and respond with a 404 Not Found status
    Rails.logger.error "Form field not found for deletion. Params: #{params.inspect}"
    flash.now[:alert] = "Form field not found."
    head :not_found
  # Catch any other unexpected errors during deletion
  rescue => e
    # Log the error and respond with a 500 Internal Server Error
    Rails.logger.error "An error occurred during field deletion: #{e.message}"
    flash.now[:alert] = "An error occurred: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def fill
    # Load form and its fields for user input
    @form = Form.includes(:form_fields).find(params[:id])
    puts "@form.stage: #{@form.stage.inspect}"
  end

def submit
  # Load the form with its fields
  @form = Form.includes(:form_fields).find(params[:id])
  Rails.logger.debug "Submit action triggered with params: #{params.inspect}"

  # Redirect if user is not logged in
  unless current_user
    redirect_to login_path, alert: "Please Sign-In before action"
    return
  end

  answers = params[:answers] || {}

  # Find participant entry for user in the workflow
  participant = Participant.find_by(user_id: current_user.id, workflow_id: @form.stage.workflow.id)

  if participant
    # Update workflow progress for the participant
    participant.update_progress(participant.current_progress + 1)
    Rails.logger.debug "Participant updated: #{participant.inspect}"
  else
    Rails.logger.warn "No Participant for User #{current_user.id} and Workflow #{@form.stage.workflow.id} found"
  end

  # Check required fields for missing values
  required_fields = @form.form_fields.select(&:required?)
  missing_fields = required_fields.select do |field|
    value = answers[field.id.to_s]
    value.blank? || (value.is_a?(Array) && value.reject(&:blank?).empty?)
  end

  if missing_fields.any?
    # Render form again with error if required fields are missing
    flash.now[:alert] = "Please fill out the required fields: #{missing_fields.map(&:title).join(', ')}"
    render :fill, status: :unprocessable_entity
    return
  end

  # Create or retrieve already submitted form
  @filled_form = FilledForm.find_or_create_by(form: @form, user: current_user)

  begin
    ActiveRecord::Base.transaction do
      # Delete old answers to prevent duplicates
      @filled_form.filled_formfields.destroy_all

      # Save each submitted answer
      answers.each do |field_id, value|
        value_to_store = value.is_a?(Array) ? value.to_json : value.to_s

        # Check if filled formfield is empty 
        if value_to_store.strip.empty?
          raise ActiveRecord::Rollback, "Please fill out the required fields!"
        end

        @filled_form.filled_formfields.create!(
          formfield_id: field_id,
          value: value_to_store
        )
      end
    end
  rescue ActiveRecord::Rollback => e
    # Handle validation failure and show error
    flash.now[:alert] = e.message
    render :fill, status: :unprocessable_entity and return
  end

  # Redirect on success
  redirect_to workflow_progress_path(@form.stage.workflow.id), notice: "Form submitted successfully."
end


  def add_field
    @workflow = Workflow.find(params[:workflow_id])
    @form = Form.find(params[:id])
    @stage = @form.stage

    # Check if form belongs to the correct workflow
    unless @stage.workflow_id == @workflow.id
      render plain: "Unauthorized", status: :unauthorized
      return
    end

    # Determine the next position in form fields
    next_position = @form.form_fields.maximum(:position).to_i + 1

    # Create new form field with default values
    @form.form_fields.create!(
      typefield: params[:field_type],
      title: "New #{params[:field_type].capitalize}",
      variableName: "new_#{params[:field_type]}",
      position: next_position
    )

    redirect_to edit_workflow_form_path(@workflow, @form), notice: "Field added."
  end

  def reorder_field
    form = Form.find(params[:id])
    field = form.form_fields.find(params[:field_id])
    direction = params[:direction]

    if direction == "up"
      # Swap positions with the field above, if it exists
      above = form.form_fields.where("position < ?", field.position).order(position: :desc).first
      if above
        field.position, above.position = above.position, field.position
        field.save!
        above.save!
      end
    elsif direction == "down"
      # Swap positions with the field below, if it exists
      below = form.form_fields.where("position > ?", field.position).order(position: :asc).first
      if below
        field.position, below.position = below.position, field.position
        field.save!
        below.save!
      end
    end

    respond_to do |format|
      format.html { redirect_to edit_workflow_form_path(form.stage.workflow, form), notice: "Field reordered." }
      format.json { head :ok }
    end
  end

  private

  # Load form and its workflow context
  def set_form
    @form = Form.find(params[:id])
    @workflow = @form.stage.workflow
  end

  # Whitelist allowed parameters for form and nested fields
  def form_params
    params.require(:form).permit(
      :title,
      form_fields_attributes: [:id, :title, :typefield, :required, :position, :_destroy, content: []]
    )
  end
end
