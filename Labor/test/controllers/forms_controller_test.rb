require "test_helper"

class FormsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
    @workflow = workflows(:one)
    @stage = stages(:first_stage)
    @form = forms(:first_form)
    @field = @form.form_fields.first
  end

  test "should get new" do
    get new_workflow_form_url(@workflow)
    assert_response :success
  end

  test "should get edit" do
    get edit_workflow_form_url(@workflow, @form)
    assert_response :success
  end

  test "should create form" do
    assert_difference("Form.count") do
      post workflow_forms_url(@workflow), params: {
        stage_id: @stage.id
      }
    end
    assert_redirected_to workflow_url(@workflow)
  end

  test "should update form" do
    patch workflow_form_url(@workflow, @form), params: {
      form: { title: "Updated Form" }
    }
    assert_redirected_to workflow_url(@workflow)
    @form.reload
    assert_equal "Updated Form", @form.title
  end

  test "should destroy form" do
    form = forms(:second_form)
    assert_difference("Form.count", -1) do
      form.destroy
    end
    assert Form.find_by(id: form.id).nil?
  end

  test "should create form with valid stage_id" do
    assert_difference("Form.count") do
      post workflow_forms_url(@workflow), params: { stage_id: @stage.id }
    end
    assert_redirected_to workflow_url(@stage.workflow)
    assert_equal "Form created successfully.", flash[:notice]
  end

  test "should not create form without stage_id" do
    post workflow_forms_url(@workflow), params: {}
    assert_redirected_to workflows_url
    assert_equal "No Stage provided.", flash[:alert]
  end

  test "should render edit on invalid update" do
    patch workflow_form_url(@workflow, @form), params: { form: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "should get fill" do
    get fill_workflow_form_path(@workflow, @form)
    assert_response :success
    assert_select "form"
  end

  test "should add field to form" do
    post add_field_workflow_form_path(@workflow, @form), params: { field_type: "text" }
    assert_redirected_to edit_workflow_form_path(@workflow, @form)
    assert_equal "Field added.", flash[:notice]

    @form.reload
    assert @form.form_fields.exists?(title: "New Text")
  end

  test "should not add field if workflow mismatch" do
    other_workflow = workflows(:two)
    post add_field_workflow_form_path(other_workflow, @form), params: { field_type: "text" }
    assert_response :unauthorized
  end
end
