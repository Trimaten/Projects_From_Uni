require "test_helper"

class WorkflowTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @workflow = Workflow.create!(
      title: "Test Workflow",
      status: "draft",
      current_stage: 1,
      owner: @user
    )
  end

  test "should be valid with valid attributes" do
    assert @workflow.valid?
  end

  test "should require a title" do
    @workflow.title = nil
    assert_not @workflow.valid?
  end

  test "should require a valid status" do
    @workflow.status = "invalid_status"
    assert_not @workflow.valid?
  end

  test "should belong to an owner" do
    @workflow.owner = nil
    assert_not @workflow.valid?
  end

  test "start_workflow should set status to active if draft" do
    @workflow.start_workflow
    assert_equal "active", @workflow.status
  end

  test "start_workflow should not change status if not draft" do
    @workflow.update(status: "completed")
    @workflow.start_workflow
    assert_equal "completed", @workflow.status
  end

  test "delete_workflow should destroy the workflow" do
    assert_difference("Workflow.count", -1) do
      @workflow.delete_workflow
    end
  end

  test "search workflow" do
    assert_includes Workflow.search("Test Workflow"), workflows(:one)
  end
end
