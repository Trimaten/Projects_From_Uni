require "test_helper"

class WorkflowsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
    @workflow = workflows(:one)
    @stage = stages(:first_stage)
    @form = forms(:first_form)
    @workflow.update!(current_stage: @stage.id)
  end

  test "should get index" do
    get workflows_url
    assert_response :success
  end

  test "should get new" do
    get new_workflow_url
    assert_response :success
  end

  test "should create workflow" do
    assert_difference('Workflow.count') do
      post workflows_url, params: {
        workflow: {
          title: 'New Workflow',
          status: 'draft',
          current_stage: @stage.id,
          owner_id: @user.id
        }
      }
    end
    assert_redirected_to workflow_url(Workflow.last)
  end

  test "should show workflow" do
    get workflow_url(@workflow)
    assert_response :success
  end

  test "should get edit" do
    get edit_workflow_url(@workflow)
    assert_response :success
  end

  test "should update workflow" do
    patch workflow_url(@workflow), params: {
      workflow: {
        title: 'Updated Workflow',
        status: 'active',
        current_stage: @stage.id
      }
    }
    assert_redirected_to dashboard_path
  end

  test "should destroy workflow" do
    assert_difference('Workflow.count', -1) do
      delete workflow_url(@workflow)
    end
    assert_redirected_to dashboard_path
  end

  test "should start workflow" do
    @workflow.update!(status: 'draft')
    post start_workflow_url(@workflow)
    assert_redirected_to workflow_url(@workflow)
    @workflow.reload
    assert_equal "active", @workflow.status
  end

  test "should view stage" do
    get view_stage_workflow_url(@workflow)
    assert_equal "Current stage: #{@stage.id}", @response.body
  end

  test "should store workflow id in session when visited" do
    get workflow_path(@workflow)
    assert_includes session[:recent_workflow_ids], @workflow.id
  end

  test "should only keep workflows according to constant" do
    (WorkflowsController::RECENT_WORKFLOWS_NUMBER + 1).times do |i|
      workflow = Workflow.create!(title: "Testworkflow #{i}", owner: @user, status: "active")
      get workflow_path(workflow)
    end
    assert_equal WorkflowsController::RECENT_WORKFLOWS_NUMBER, session[:recent_workflow_ids].size
  end

  test "should not duplicate workflow id in session" do
    2.times { get workflow_path(@workflow) }
    assert_equal [@workflow.id], session[:recent_workflow_ids]
  end

end
