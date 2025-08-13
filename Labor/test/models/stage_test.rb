require "test_helper"

class StageTest < ActiveSupport::TestCase
  fixtures :users, :stages, :forms, :formfields, :workflows

  test "should set user_id" do
    stage = stages(:first_stage)
    user = users(:one)
    stage.user_id = user.id
    assert_equal user.id, stage.user_id, "User ID was not set correctly"
  end

  test "create stage with valid attribute but without workflow" do
    stage = Stage.new(title: "Test Stage")
    assert_not stage.save, "Saved the stage without a workflow (which is required)"
  end

  test "should not save stage without title" do
    stage = Stage.new(workflow: workflows(:one))
    assert_not stage.save, "Saved the stage without a title"
  end

  test "should not save stage with too long title" do
    stage = Stage.new(title: "a" * 129, workflow: workflows(:one))
    assert_not stage.save, "Saved the stage with a title that is too long"
  end

  test "should save stage with special characters in title" do
    stage = Stage.new(title: "Stage!@#", workflow: workflows(:one), position: 5)
    assert stage.save, "Failed to save the stage with special characters in the title"
  end

  test "should return stages with user_id" do
    user = users(:one)
    stage = Stage.new(title: "Test Stage", user_id: user.id, workflow: workflows(:one), position: 5)
    assert stage.save, "Failed to save the stage with user_id"
    assert_equal stage.user_id, user.id, "User ID was not set correctly"
  end

  test "should associate form correctly" do
    stage = stages(:first_stage)
    form = forms(:first_form)
    assert_equal form, stage.form, "Form was not associated correctly with the stage"
  end

  test "should not save stage with invalid user_id" do 
    stage = Stage.new(title: "Test Stage", user_id: -1, workflow: workflows(:one))
    assert_not stage.save, "Saved the stage with an invalid user_id"
  end

  test "should not save stage with invalid user_id decimal" do
    stage = Stage.new(title: "Test Stage", user_id: 1.2, workflow: workflows(:one))
    assert_not stage.save, "Saved the stage with an invalid user_id"
  end
  test "should not save stage with position less than or equal to 0" do
    stage = Stage.new(title: "Invalid Position", workflow: workflows(:one), position: 0)
    assert_not stage.save, "Saved the stage with a non-positive position"
    
    stage.position = -5
    assert_not stage.save, "Saved the stage with a negative position"
  end
  test "should set default position before create if not provided" do
    workflow = workflows(:one)
    existing_max = workflow.stages.maximum(:position) || 0
    stage = Stage.new(title: "Auto Position", workflow: workflow)
    stage.save!
    assert_equal existing_max + 1, stage.position, "Stage position was not set correctly"
  end
end
