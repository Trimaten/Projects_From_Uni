require "test_helper"

class StagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  fixtures :users, :workflows, :stages

  setup do
    @user = users(:one)
    sign_in @user

    @workflow = workflows(:one)
    @stage = stages(:first_stage)
  end

  test "should get edit stage" do
    get edit_workflow_stage_path(@workflow, @stage)
    assert_response :success
  end

  test "should update stage title" do
    patch workflow_stage_path(@workflow, @stage), params: {
      stage: { title: "Updated Stage Title" }
    }
    assert_redirected_to workflow_path(@workflow)
    @stage.reload
    assert_equal "Updated Stage Title", @stage.title
  end

  test "should update stage order" do
    stage2 = stages(:second_stage)
    stage3 = stages(:third_stage)

    new_order = [stage3.id, stage2.id, @stage.id]
    patch workflow_stage_path(@workflow, @stage), params: {
      stage: {
        title: @stage.title,
        stage_order: new_order.join(",")
      }
    }

    assert_redirected_to workflow_path(@workflow)
    assert_equal 1, @workflow.stages.find(stage3.id).reload.position
    assert_equal 2, @workflow.stages.find(stage2.id).reload.position
    assert_equal 3, @stage.reload.position
  end

  test "should not update with invalid data" do
    patch workflow_stage_path(@workflow, @stage), params: {
      stage: { title: "" }
    }
    assert_response :success
  end

  test "should redirect if stage not found" do
    invalid_id = -1
    get edit_workflow_stage_path(@workflow, invalid_id)
    assert_redirected_to workflow_path(@workflow)
    follow_redirect!
  end
end
